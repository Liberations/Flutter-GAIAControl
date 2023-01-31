import 'dart:async';
import 'dart:collection';

import '../../Log.dart';
import '../../StringUtils.dart';
import 'RWCP.dart';
import 'RWCPListener.dart';
import 'Segment.dart';

class RWCPClient {
  /**
   * <p>The tag to display for logs.</p>
   */
  final String TAG = "RWCPClient";

  /**
   * <p>The listener to communicate with the application and send segments.</p>
   */
  final RWCPListener mListener;

  /**
   * The sequence number of the last sequence which had been acknowledged by the Server.
   */
  int mLastAckSequence = 0;

  /**
   * The next sequence number which will be send.
   */
  int mNextSequence = 0;

  /**
   * The window size to use when starting a transfer.
   */
  int mInitialWindow = RWCP.WINDOW_DEFAULT;

  /**
   * The maximum size of the window to use when adjusting the window size.
   */
  int mMaximumWindow = RWCP.WINDOW_MAX;

  /**
   * The window represents the maximum number of segments which can be sent simultaneously.
   */
  int mWindow = RWCP.WINDOW_DEFAULT;

  /**
   * The credit number represents the number of segments which can still be send to fill the current window.
   */
  int mCredits = RWCP.WINDOW_DEFAULT;

  /**
   * When receiving a GAP or when an operation is timed out, this client resends the unacknowledged data and stops
   * any other running operation.
   */
  bool mIsResendingSegments = false;

  /**
   * The state of the Client.
   */
  int mState = RWCPState.LISTEN;

  /**
   * The queue of data which are waiting to be sent.
   */

  var mPendingData = ListQueue<List<int>>();

  /**
   * The queue of segments which have been sent but have not been acknowledged yet.
   */

  var mUnacknowledgedSegments = ListQueue<Segment>();

  /**
   * To know if a time out is running.
   */
  bool isTimeOutRunning = false;

  /**
   * The time used to time out the DATA segments.
   */
  int mDataTimeOutMs = RWCP.DATA_TIMEOUT_MS_DEFAULT;

  /**
   * <p>To show the debug logs indicating when a method had been reached.</p>
   */
  bool mShowDebugLogs = true;

  /**
   * To know the number of segments which had been acknowledged in a row with DATA_ACK.
   */
  int mAcknowledgedSegments = 0;
  Timer? _timer;

  RWCPClient(this.mListener);

  bool isRunningASession() {
    return mState != RWCPState.LISTEN;
  }

  void showDebugLogs(bool show) {
    mShowDebugLogs = show;
    Log.i(TAG, "Debug logs are now " + (show ? "activated" : "deactivated") + ".");
  }

  bool sendData(List<int> bytes) {
    mPendingData.add(bytes);
    if (mState == RWCPState.LISTEN) {
      return startSession();
    } else if (mState == RWCPState.ESTABLISHED && !isTimeOutRunning) {
      sendDataSegment();
      return true;
    }

    return true;
  }

  void cancelTransfer() {
    logState("cancelTransfer");

    if (mState == RWCPState.LISTEN) {
      Log.i(TAG, "cancelTransfer: no ongoing transfer to cancel.");
      return;
    }

    reset(true);

    if (!sendRSTSegment()) {
      Log.w(TAG, "Sending of RST segment has failed, terminating session.");
      terminateSession();
    }
  }

  bool onReceiveRWCPSegment(List<int>? bytes) {
    if (bytes == null) {
      Log.w(TAG, "onReceiveRWCPSegment called with a null bytes array.");
      return false;
    }

    if (bytes.length < RWCPSegment.REQUIRED_INFORMATION_LENGTH) {
      String message =
          "Analyse of RWCP Segment failed: the byte array does not contain the minimum " + "required information.";
      if (mShowDebugLogs) {
        message += "\n\tbytes=" + StringUtils.byteToHexString(bytes);
      }
      Log.w(TAG, message);
      return false;
    }

    // getting the segment information from the bytes
    Segment segment = Segment.parse(bytes);
    int code = segment.getOperationCode();
    if (code == -1) {
      Log.w(
          TAG,
          "onReceivedRWCPSegment failed to get a RWCP segment from given bytes: $code data->" +
              StringUtils.byteToHexString(bytes));
      return false;
    }

    Log.d(TAG, "onReceiveRWCPSegment code$code");
    // handling of a segment depends on the operation code.
    switch (code) {
      case RWCPOpCodeServer.SYN_ACK:
        return receiveSynAck(segment);
      case RWCPOpCodeServer.DATA_ACK:
        return receiveDataAck(segment);
      case RWCPOpCodeServer.RST:
        /*case RWCP.OpCode.Server.RST_ACK:*/
        return receiveRST(segment);
      case RWCPOpCodeServer.GAP:
        return receiveGAP(segment);
      default:
        Log.w(TAG, "Received unknown operation code: $code");
        return false;
    }
  }

  int getInitialWindowSize() {
    return mInitialWindow;
  }

  bool setInitialWindowSize(int size) {
    logState("set initial window size to $size");

    if (mState != RWCPState.LISTEN) {
      Log.w(TAG, "FAIL to set initial window size to $size: not possible when there is an ongoing " + "session.");
      return false;
    }

    if (size <= 0 || size > mMaximumWindow) {
      Log.w(TAG, "FAIL to set initial window to $size: size is out of range.");
      return false;
    }

    mInitialWindow = size;
    mWindow = mInitialWindow; // not in an ongoing session, window is set up to the initial value
    return true;
  }

  int getMaximumWindowSize() {
    return mMaximumWindow;
  }

  bool setMaximumWindowSize(int size) {
    logState("set maximum window size to $size");

    if (mState != RWCPState.LISTEN) {
      Log.w(TAG, "FAIL to set maximum window size to $size: not possible when there is an ongoing " + "session.");
      return false;
    }

    if (size <= 0 || size > RWCP.WINDOW_MAX) {
      Log.w(TAG, "FAIL to set maximum window to $size: size is out of range.");
      return false;
    }

    if (mInitialWindow > mMaximumWindow) {
      Log.w(TAG, "FAIL to set maximum window to $size: initial window is $mInitialWindow.");
      return false;
    }

    mMaximumWindow = size;
    if (mWindow > mMaximumWindow) {
      Log.i(TAG, "window is updated to be less than the maximum window size ( $mInitialWindow).");
      mWindow = mMaximumWindow;
    }
    return true;
  }

  bool receiveRST(Segment segment) {
    if (mShowDebugLogs) {
      Log.d(TAG, "Receive RST or RST_ACK for sequence ${segment.getSequenceNumber()}");
    }

    switch (mState) {
      case RWCPState.SYN_SENT:
        Log.i(TAG, "Received RST (sequence ${segment.getSequenceNumber()}) in SYN_SENT state, ignoring " + "segment.");
        return true;

      case RWCPState.ESTABLISHED:
        // received RST
        Log.w(
            TAG,
            "Received RST (sequence ${segment.getSequenceNumber()}) in ESTABLISHED state, " +
                "terminating session, transfer failed.");
        terminateSession();
        mListener.onTransferFailed();
        return true;

      case RWCPState.CLOSING:
        // received RST_ACK
        cancelTimeOut();
        validateAckSequence(RWCPOpCodeClient.RST, segment.getSequenceNumber());
        reset(false);
        if (mPendingData.isNotEmpty) {
          // expected when starting a session: RST sent prior SYN, sending SYN to start the session
          if (!sendSYNSegment()) {
            Log.w(TAG, "Start session of RWCP data transfer failed: sending of SYN failed.");
            terminateSession();
            mListener.onTransferFailed();
          }
        } else {
          // RST is acknowledged: transfer is finished
          mListener.onTransferFinished();
        }
        return true;

      case RWCPState.LISTEN:
      default:
        Log.w(
            TAG,
            "Received unexpected RST segment with sequence=${segment.getSequenceNumber()}" +
                " while in state " +
                RWCP.getStateLabel(mState));
        return false;
    }
  }

  bool sendSYNSegment() {
    bool done = false;
    mState = RWCPState.SYN_SENT;
    Segment segment = Segment.get(RWCPOpCodeClient.SYN, mNextSequence);
    done = sendSegment(segment, RWCP.SYN_TIMEOUT_MS);
    if (done) {
      mUnacknowledgedSegments.add(segment);
      mNextSequence = increaseSequenceNumber(mNextSequence);
      mCredits--;
      logState("send SYN segment");
    }
    return done;
  }

  void logState(String label) {
    if (mShowDebugLogs) {
      String message = label +
          "\t\t\tstate=" +
          RWCP.getStateLabel(mState) +
          "\n\tWindow: \tcurrent = " +
          "$mWindow" +
          " \t\tdefault = " +
          "$mInitialWindow" +
          " \t\tcredits = " +
          "$mCredits" +
          "\n\tSequence: \tlast = " +
          "$mLastAckSequence" +
          " \t\tnext = " +
          "$mNextSequence" +
          "\n\tPending: \tPSegments = " +
          "${mUnacknowledgedSegments.length}" +
          " \t\tPData = " +
          "${mPendingData.length}";
      Log.d(TAG, message);
    }
  }

  bool startSession() {
    logState("startSession");

    if (mState != RWCPState.LISTEN) {
      Log.w(TAG, "Start RWCP session failed: already an ongoing session.");
      return false;
    }

    // it is recommended to send a RST and then a SYN to make sure the Server side is in the right state.
    // This client first sends a RST segment, waits to get a RST_ACK segment and sends the SYN segment.
    // The sending of the SYN happens if there is some pending data waiting to be sent.
    if (sendRSTSegment()) {
      return true;
      // wait for receiveRST to be called.
    } else {
      Log.w(TAG, "Start RWCP session failed: sending of RST segment failed.");
      terminateSession();
      return false;
    }
  }

  void terminateSession() {
    logState("terminateSession");
    reset(true);
  }

  bool sendRSTSegment() {
    if (mState == RWCPState.CLOSING) {
      // RST already sent waiting to be acknowledged
      return true;
    }

    bool done = false;
    reset(false);
    mState = RWCPState.CLOSING;
    Segment segment = Segment.get(RWCPOpCodeClient.RST, mNextSequence);
    done = sendSegment(segment, RWCP.RST_TIMEOUT_MS);
    if (done) {
      mUnacknowledgedSegments.add(segment);
      mNextSequence = increaseSequenceNumber(mNextSequence);
      mCredits--;
      logState("send RST segment");
    }
    return done;
  }

  bool sendSegment(Segment segment, int timeout) {
    List<int> bytes = segment.getBytes();
    if (mListener.sendRWCPSegment(bytes)) {
      startTimeOut(timeout);
      return true;
    }

    return false;
  }

  void startTimeOut(int delay) {
    if (isTimeOutRunning) {
      _timer?.cancel();
    }

    isTimeOutRunning = true;
    _timer = Timer(Duration(milliseconds: delay), () {
      onTimeOut();
    });
  }

  void onTimeOut() {
    if (isTimeOutRunning) {
      isTimeOutRunning = false;
      mIsResendingSegments = true;
      mAcknowledgedSegments = 0;

      if (mShowDebugLogs) {
        Log.i(TAG, "TIME OUT > re sending segments");
      }

      if (mState == RWCPState.ESTABLISHED) {
        // Timed out segments are DATA segments: increasing data time out value
        mDataTimeOutMs *= 2;
        if (mDataTimeOutMs > RWCP.DATA_TIMEOUT_MS_MAX) {
          mDataTimeOutMs = RWCP.DATA_TIMEOUT_MS_MAX;
        }

        resendDataSegment();
      } else {
        // SYN or RST segments are timed out
        resendSegment();
      }
    }
  }

  void resendSegment() {
    if (mState == RWCPState.ESTABLISHED) {
      Log.w(TAG, "Trying to resend non data segment while in ESTABLISHED state.");
      return;
    }

    mIsResendingSegments = true;
    mCredits = mWindow;

    // resend the unacknowledged segments corresponding to the window
    for (Segment segment in mUnacknowledgedSegments) {
      int delay = (segment.getOperationCode() == RWCPOpCodeClient.SYN)
          ? RWCP.SYN_TIMEOUT_MS
          : (segment.getOperationCode() == RWCPOpCodeClient.RST)
              ? RWCP.RST_TIMEOUT_MS
              : mDataTimeOutMs;
      sendSegment(segment, delay);
      mCredits--;
    }
    logState("resend segments");

    mIsResendingSegments = false;
  }

  void resendDataSegment() {
    if (mState != RWCPState.ESTABLISHED) {
      Log.w(TAG, "Trying to resend data segment while not in ESTABLISHED state.");
      return;
    }

    mIsResendingSegments = true;
    mCredits = mWindow;
    logState("reset credits");

    // if they are more unacknowledged segments than available credits, these extra segments are not anymore
    // unacknowledged but pending
    int moved = 0;
    while (mUnacknowledgedSegments.length > mCredits) {
      Segment segment = mUnacknowledgedSegments.last;
      if (segment.getOperationCode() == RWCPOpCodeClient.DATA) {
        mUnacknowledgedSegments.removeLast();
        mPendingData.addFirst(segment.getPayload());
        moved++;
      } else {
        Log.w(TAG, "Segment " + segment.toString() + " in pending segments but not a DATA segment.");
        break;
      }
    }

    // if some segments have been moved to the pending state, the next sequence number has changed.
    mNextSequence = decreaseSequenceNumber(mNextSequence, moved);

    // resend the unacknowledged segments corresponding to the window
    for (var segment in mUnacknowledgedSegments) {
      sendSegment(segment, mDataTimeOutMs);
      mCredits--;
    }

    logState("Resend DATA segments");

    mIsResendingSegments = false;

    if (mCredits > 0) {
      sendDataSegment();
    }
  }

  void sendDataSegment() {
    while (mCredits > 0 && mPendingData.isNotEmpty && !mIsResendingSegments && mState == RWCPState.ESTABLISHED) {
      List<int> data = mPendingData.removeFirst();
      Segment segment = Segment.get(RWCPOpCodeClient.DATA, mNextSequence, payload: data);
      sendSegment(segment, mDataTimeOutMs);
      mUnacknowledgedSegments.add(segment);
      mNextSequence = increaseSequenceNumber(mNextSequence);
      mCredits--;
    }
    logState("send DATA segments");
  }

  int increaseSequenceNumber(int sequence) {
    return (sequence + 1) % (RWCP.SEQUENCE_NUMBER_MAX + 1);
  }

  int decreaseSequenceNumber(int sequence, int decrease) {
    return (sequence - decrease + RWCP.SEQUENCE_NUMBER_MAX + 1) % (RWCP.SEQUENCE_NUMBER_MAX + 1);
  }

  void reset(bool complete) {
    mLastAckSequence = -1;
    mNextSequence = 0;
    mState = RWCPState.LISTEN;
    mUnacknowledgedSegments.clear();
    mWindow = mInitialWindow;
    mAcknowledgedSegments = 0;
    mCredits = mWindow;
    cancelTimeOut();
    if (complete) {
      mPendingData.clear();
    }
    logState("reset");
  }

  void cancelTimeOut() {
    if (isTimeOutRunning) {
      _timer?.cancel();
      isTimeOutRunning = false;
    }
  }

  bool receiveSynAck(Segment segment) {
    if (mShowDebugLogs) {
      Log.d(TAG, "Receive SYN_ACK for sequence ${segment.getSequenceNumber()}");
    }

    switch (mState) {
      case RWCPState.SYN_SENT:
        // expected behavior: start to send the data
        cancelTimeOut();
        int validated = validateAckSequence(RWCPOpCodeClient.SYN, segment.getSequenceNumber());
        if (validated >= 0) {
          mState = RWCPState.ESTABLISHED;
          if (mPendingData.isNotEmpty) {
            sendDataSegment();
          }
        } else {
          Log.w(TAG, "Receive SYN_ACK with unexpected sequence number: ${segment.getSequenceNumber()}");
          terminateSession();
          mListener.onTransferFailed();
          sendRSTSegment();
        }
        return true;

      case RWCPState.ESTABLISHED:
        // DATA might have been lost, resending them
        cancelTimeOut();
        if (mUnacknowledgedSegments.isNotEmpty) {
          resendDataSegment();
        }
        return true;

      case RWCPState.CLOSING:
      case RWCPState.LISTEN:
      default:
        Log.w(
            TAG,
            "Received unexpected SYN_ACK segment with header " +
                "${segment.getHeader()}" +
                " while in state " +
                RWCP.getStateLabel(mState));
        return false;
    }
  }

  int validateAckSequence(final int code, final int sequence) {
    final int NOT_VALIDATED = -1;

    if (sequence < 0) {
      Log.w(TAG, "Received ACK sequence ($sequence) is less than 0.");
      return NOT_VALIDATED;
    }

    if (sequence > RWCP.SEQUENCE_NUMBER_MAX) {
      Log.w(
          TAG,
          "Received ACK sequence ($sequence) is bigger than its maximum value (" +
              "${RWCP.SEQUENCE_NUMBER_MAX}" +
              ").");
      return NOT_VALIDATED;
    }

    if (mLastAckSequence < mNextSequence && (sequence < mLastAckSequence || sequence > mNextSequence)) {
      Log.w(
          TAG,
          "Received ACK sequence ($sequence) is out of interval: last received is " +
              "$mLastAckSequence" +
              " and next will be " +
              "$mNextSequence");
      return NOT_VALIDATED;
    }

    if (mLastAckSequence > mNextSequence && sequence < mLastAckSequence && sequence > mNextSequence) {
      Log.w(
          TAG,
          "Received ACK sequence ($sequence) is out of interval: last received is " +
              "$mLastAckSequence" +
              " and next will be " +
              "$mNextSequence");
      return NOT_VALIDATED;
    }

    int acknowledged = 0;
    int nextAckSequence = mLastAckSequence;
    while (nextAckSequence != sequence) {
      nextAckSequence = increaseSequenceNumber(nextAckSequence);
      if (removeSegmentFromQueue(code, nextAckSequence)) {
        mLastAckSequence = nextAckSequence;
        if (mCredits < mWindow) {
          mCredits++;
        }
        acknowledged++;
      } else {
        Log.w(TAG,
            "Error validating sequence " + "$nextAckSequence" + ": no corresponding segment in " + "pending segments.");
      }
    }

    logState("$acknowledged" + " segment(s) validated with ACK sequence(code=$code seq=$sequence");

    // increase the window size if qualified.
    increaseWindow(acknowledged);

    return acknowledged;
  }

  bool removeSegmentFromQueue(int code, int sequence) {
    for (Segment segment in mUnacknowledgedSegments) {
      if (segment.getOperationCode() == code && segment.getSequenceNumber() == sequence) {
        mUnacknowledgedSegments.remove(segment);
        return true;
      }
    }
    Log.w(TAG, "Pending segments does not contain acknowledged segment: code=$code \tsequence=$sequence");
    return false;
  }

  void increaseWindow(int acknowledged) {
    mAcknowledgedSegments += acknowledged;
    if (mAcknowledgedSegments > mWindow && mWindow < mMaximumWindow) {
      mAcknowledgedSegments = 0;
      mWindow++;
      mCredits++;
      logState("increase window to $mWindow");
    }
  }

  bool receiveDataAck(Segment segment) {
    if (mShowDebugLogs) {
      Log.d(TAG, "Receive DATA_ACK for sequence ${segment.getSequenceNumber()}");
    }

    switch (mState) {
      case RWCPState.ESTABLISHED:
        cancelTimeOut();
        int sequence = segment.getSequenceNumber();
        int validated = validateAckSequence(RWCPOpCodeClient.DATA, sequence);
        if (validated >= 0) {
          if (mCredits > 0 && !mPendingData.isEmpty) {
            sendDataSegment();
          } else if (mPendingData.isEmpty && mUnacknowledgedSegments.isEmpty) {
            // no more data to send: close session
            sendRSTSegment();
          } else if (mPendingData.isEmpty /*&& !mUnacknowledgedSegments.isEmpty()*/
              ||
              mCredits == 0 /*&& !mPendingData.isEmpty()*/) {
            // no more data to send but still some waiting to be acknowledged
            // or no credits and still some data to send
            startTimeOut(mDataTimeOutMs);
          }
          mListener.onTransferProgress(validated);
        }
        return true;

      case RWCPState.CLOSING:
        // RST had been sent, wait for the RST time out or RST ACK
        if (mShowDebugLogs) {
          Log.i(TAG,
              "Received DATA_ACK(${segment.getSequenceNumber()}) segment while in state CLOSING: segment discarded.");
        }
        return true;

      case RWCPState.SYN_SENT:
      case RWCPState.LISTEN:
      default:
        Log.w(
            TAG,
            "Received unexpected DATA_ACK segment with sequence ${segment.getSequenceNumber()}" +
                " while in state " +
                RWCP.getStateLabel(mState));
        return false;
    }
  }

  bool receiveGAP(Segment segment) {
    if (mShowDebugLogs) {
      Log.d(TAG, "Receive GAP for sequence ${segment.getSequenceNumber()}");
    }

    switch (mState) {
      case RWCPState.ESTABLISHED:
        if (mLastAckSequence > segment.getSequenceNumber()) {
          Log.i(TAG, "Ignoring GAP (${segment.getSequenceNumber()}) as last ack sequence is $mLastAckSequence.");
          return true;
        }
        if (mLastAckSequence <= segment.getSequenceNumber()) {
          // Sequence number in GAP implies lost DATA_ACKs
          // adjust window
          decreaseWindow();
          // validate the acknowledged segments if not known.
          validateAckSequence(RWCPOpCodeClient.DATA, segment.getSequenceNumber());
        }

        cancelTimeOut();
        resendDataSegment();
        return true;

      case RWCPState.CLOSING:
        // RST had been sent, wait for the RST time out or RST ACK
        if (mShowDebugLogs) {
          Log.i(TAG, "Received GAP(${segment.getSequenceNumber()}) segment while in state CLOSING: segment discarded.");
        }
        return true;

      case RWCPState.SYN_SENT:
      case RWCPState.LISTEN:
      default:
        Log.w(
            TAG,
            "Received unexpected GAP segment with header ${segment.getHeader()} while in state " +
                RWCP.getStateLabel(mState));
        return false;
    }
  }

  void decreaseWindow() {
    mWindow = ((mWindow - 1) ~/ 2) + 1;
    if (mWindow > mMaximumWindow || mWindow < 1) {
      mWindow = 1;
    }

    mAcknowledgedSegments = 0;
    mCredits = mWindow;

    logState("decrease window to $mWindow");
  }
}

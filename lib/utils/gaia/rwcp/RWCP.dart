class RWCP {
  /**
   * <p>The maximum size of the window.</p>
   */
  static const int WINDOW_MAX = 32;

  /**
   * <p>The default size of the window.</p>
   */
  static const int WINDOW_DEFAULT = 15;

  /**
   * <p>The delay in millisecond to time out a SYN operation.</p>
   */
  static const int SYN_TIMEOUT_MS = 1000;

  /**
   * <p>The delay in millisecond to time out a RST operation.</p>
   */
  static const int RST_TIMEOUT_MS = 1000;

  /**
   * <p>The default delay in millisecond to time out a DATA operation.</p>
   */
  static const int DATA_TIMEOUT_MS_DEFAULT = 100;

  /**
   * <p>The maximum delay in millisecond to time out a DATA operation.</p>
   */
  static const int DATA_TIMEOUT_MS_MAX = 2000;

  /**
   * <p>The maximum number of a sequence is 63 which correspond to the maximum value represented by 6 bits.</p>
   */
  static const int SEQUENCE_NUMBER_MAX = 63;

  /**
   * <p>This method builds a human readable label corresponding to the given state value as "CLOSING",
   * "ESTABLISHED", "LISTEN" and "SYN_SENT". It returns "Unknown state" for any other value.</p>
   *
   * @param state
   *          The state for which is required a human readable value.
   *
   * @return A human readable label for the given value.
   */
  static String getStateLabel(int state) {
    switch (state) {
      case RWCPState.CLOSING:
        return "CLOSING";
      case RWCPState.ESTABLISHED:
        return "ESTABLISHED";
      case RWCPState.LISTEN:
        return "LISTEN";
      case RWCPState.SYN_SENT:
        return "SYN_SENT";
      default:
        return "Unknown state ($state)";
    }
  }
}

class RWCPState {
  /**
   * The Client is ready for the application to request that a Write Command(s) be sent to the Server.
   */
  static const int LISTEN = 0;

  /**
   * The Client has started a session and is waiting for the Server to acknowledge the start.
   */
  static const int SYN_SENT = 1;

  /**
   * The Client sends data to the Server.
   */
  static const int ESTABLISHED = 2;

  /**
   * The Client has terminated the connection the connection and the Client is waiting for the Server to
   * acknowledge the termination request.
   */
  static const int CLOSING = 3;
}

class RWCPOpCodeClient {
  /**
   * Data sent to the Server by the Client.
   */
  static const int DATA = 0;

  /**
   * Used to synchronise and start a session by the Client.
   */
  static const int SYN = 1;

  /**
   * RST is used by the Client to terminate a session.
   */
  static const int RST = 2;

  /**
   * Undefined operation code, to not be used.
   */
  static const int RESERVED = 3;
}

class RWCPOpCodeServer {
  /**
   * Used by the Server to acknowledge the data sent to the Server.
   */
  static const int DATA_ACK = 0;

  /**
   * Used by the Server to acknowledge the SYN segment.
   */
  static const int SYN_ACK = 1;

  /**
   * RST is used by the Server to terminate a session.
   * RST_ACK is used by the Server to acknowledge the Client’s request to terminate a session.
   */
  static const int RST = 2;

  static const int RST_ACK = 2;

  /**
   * Used by the Server to indicate that the Server static consted a DATA segment that was out-of-sequence.
   */
  static const int GAP = 3;
}

class RWCPSegment {
  /**
   * The offset for the header information.
   */
  static const int HEADER_OFFSET = 0;

  /**
   * The number of bytes which contain the header.
   */
  static const int HEADER_LENGTH = 1;

  /**
   * The offset for the payload information.
   */
  static const int PAYLOAD_OFFSET = HEADER_OFFSET + HEADER_LENGTH;

  /**
   * The minimum length of a segment.
   */
  static const int REQUIRED_INFORMATION_LENGTH = HEADER_LENGTH;

/**
 * <p>The header of a RWCP segment contains the information to identify the segment: a sequence number and an
 * operation code. The header is contained in one byte for which the bits are allocated as follows:</p>
 * <blockquote><pre>
 * 0 bit     ...         6          7          8
 * +----------+----------+----------+----------+
 * |   SEQUENCE NUMBER   |   OPERATION CODE    |
 * +----------+----------+----------+----------+
 * </pre></blockquote>
 */
}

class SegmentHeader {
  /**
   * The bit offset for the sequence number.
   */
  static const int SEQUENCE_NUMBER_BIT_OFFSET = 0;

  /**
   * The number of bits which contain the sequence number information.
   */
  static const int SEQUENCE_NUMBER_BITS_LENGTH = 6;

  /**
   * The bit offset for the operation code.
   */
  static const int OPERATION_CODE_BIT_OFFSET = SEQUENCE_NUMBER_BIT_OFFSET + SEQUENCE_NUMBER_BITS_LENGTH;

  /**
   * The number of bits which contain the operation code.
   */
  static const int OPERATION_CODE_BITS_LENGTH = 2;
}

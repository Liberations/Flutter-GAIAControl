abstract class RWCPListener{
  /**
   * <p>To send the bytes of a RWCP segment to a connected Server.</p>
   *
   * @param bytes
   *          The bytes to send.
   *
   * @return True if the sending could be handled.
   */
  bool sendRWCPSegment(List<int> bytes);

  /**
   * <p>Called when the transfer with RWCP has failed. The transfer fails in the following cases:
   * <ul>
   *     <li>The sending of a segment fails at the transport layer.</li>
   *     <li>The Server sent a {@link com.qualcomm.qti.gaiacontrol.rwcp.RWCP.OpCode.Client#RST RST} segment.</li>
   * </ul></p>
   */
  void onTransferFailed();

  /**
   * <p>Called when the transfer of all the data given to this client had been successfully sent and
   * acknowledged.</p>
   */
  void onTransferFinished();

  /**
   * <p>Called when some new segments had been acknowledged to inform the listener.</p>
   *
   * @param acknowledged
   *              The number of segments which had been acknowledged.
   */
  void onTransferProgress(int acknowledged);
}
class ConfirmationType{
  /**
   * <p>When the manager receives the
   * {@link OpCodes.Enum#UPGRADE_TRANSFER_COMPLETE_IND
   * UPGRADE_TRANSFER_COMPLETE_IND} message, the board is asking for a confirmation to
   * {@link OpCodes.UpgradeTransferCompleteRES.Action#CONTINUE CONTINUE}
   * or {@link OpCodes.UpgradeTransferCompleteRES.Action#ABORT ABORT}  the
   * process.</p>
   */
  static const int TRANSFER_COMPLETE = 1;
  /**
   * <p>When the manager receives the
   * {@link OpCodes.Enum#UPGRADE_COMMIT_REQ UPGRADE_COMMIT_REQ} message, the
   * board is asking for a confirmation to
   * {@link OpCodes.UpgradeCommitCFM.Action#CONTINUE CONTINUE}
   * or {@link OpCodes.UpgradeCommitCFM.Action#ABORT ABORT}  the process.</p>
   */
  static const int COMMIT = 2;
  /**
   * <p>When the resume point
   * {@link ResumePoints.Enum#IN_PROGRESS IN_PROGRESS} is reached, the board
   * is expecting to receive a confirmation to
   * {@link OpCodes.UpgradeInProgressRES.Action#CONTINUE CONTINUE}
   * or {@link OpCodes.UpgradeInProgressRES.Action#ABORT ABORT} the process.</p>
   */
  static const int IN_PROGRESS = 3;
  /**
   * <p>When the Host receives
   * {@link com.qualcomm.qti.libraries.vmupgrade.codes.ReturnCodes.Enum#WARN_SYNC_ID_IS_DIFFERENT WARN_SYNC_ID_IS_DIFFERENT},
   * the listener has to ask if the upgrade should continue or not.</p>
   */
  static const int WARNING_FILE_IS_DIFFERENT = 4;
  /**
   * <p>>When the Host receives
   * {@link com.qualcomm.qti.libraries.vmupgrade.codes.ReturnCodes.Enum#ERROR_BATTERY_LOW ERROR_BATTERY_LOW},the
   * listener has to ask if the upgrade should continue or not.</p>
   */
  static const int BATTERY_LOW_ON_DEVICE = 5;
}
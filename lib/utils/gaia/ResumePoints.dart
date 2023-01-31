class ResumePoints{
  /**
   * This is the resume point "0", that means the upgrade will start from the beginning, the UPGRADE_START_DATA_REQ
   * request.
   */
 static const int DATA_TRANSFER = 0x00;
  /**
   * This is the 1st resume point, that means the upgrade should resume from the UPGRADE_IS_CSR_VALID_DONE_REQ
   * request.
   */
 static const int VALIDATION = 0x01;
  /**
   * This is the 2nd resume point, that means the upgrade should resume from the UPGRADE_TRANSFER_COMPLETE_RES request.
   */
 static const int TRANSFER_COMPLETE = 0x02;
  /**
   * This is the 3rd resume point, that means the upgrade should resume from the UPGRADE_IN_PROGRESS_RES request.
   */
 static const int IN_PROGRESS = 0x03;
  /**
   * This is the 4th resume point, that means the upgrade should resume from the UPGRADE_COMMIT_CFM confirmation request.
   */
 static const int COMMIT = 0x04;
}
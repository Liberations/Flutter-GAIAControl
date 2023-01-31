class UpgradeStartCFMStatus{
  /**
   * Value for an {@link Enum#UPGRADE_START_CFM UPGRADE_START_CFM} message when the device is ready to start
   * the upgrade process.
   */
  static const int SUCCESS = 0x00;
  /**
   * Value for an {@link Enum#UPGRADE_START_CFM UPGRADE_START_CFM} message when the device is not ready to
   * start the upgrade process.
   */
  static const int ERROR_APP_NOT_READY = 0x09;
}
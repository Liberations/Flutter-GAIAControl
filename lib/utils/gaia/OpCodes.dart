class OpCodes {
  /// <p>To request an upgrade procedure to start.</p> <dl> <dt><b>Content</b></dt><dd>none</dd> <dt><b>Previous
  /// message</b></dt><dd>{@link OpCodes.Enum#UPGRADE_SYNC_CFM UPGRADE_SYNC_CFM} from device.</dd> <dt><b>Next
  /// message</b></dt><dd>{@link OpCodes.Enum#UPGRADE_START_CFM UPGRADE_START_CFM} from the device.</dd> </dl>
  static const UPGRADE_START_REQ = 0x01;

  /// <p>To confirm the start of the upgrade procedure.</p> <dl> <dt><b>Content</b></dt><dd>Contains a value to
  /// indicate if the Device is ready for the upgrade, see {@link UpgradeStartCFM}.</dd> <dt><b>Previous
  /// message</b></dt><dd>{@link OpCodes.Enum#UPGRADE_START_REQ UPGRADE_START_REQ}</dd> <dt><b>Next
  /// message</b></dt><dd>depends on the {@link ResumePostatic consts} value received by the Host in the {@link
  /// OpCodes.Enum#UPGRADE_SYNC_CFM UPGRADE_SYNC_CFM} message: <table> <tr> <td>{@link
  /// ResumePostatic consts.Enum#DATA_TRANSFER DATA_TRANSFER}</td> <td> &#8658; {@link OpCodes.Enum#UPGRADE_START_REQ} from
  /// application.</td> </tr> <tr> <td>{@link ResumePostatic consts.Enum#VALIDATION VALIDATION}</td> <td> &#8658; {@link
  /// OpCodes.Enum#UPGRADE_IS_VALIDATION_DONE_REQ} from application.</td> </tr> <tr> <td>{@link
  /// ResumePostatic consts.Enum#TRANSFER_COMPLETE TRANSFER_COMPLETE}</td> <td> &#8658; {@link
  /// OpCodes.Enum#UPGRADE_TRANSFER_COMPLETE_RES} from application.</td> </tr> <tr> <td>{@link
  /// ResumePostatic consts.Enum#IN_PROGRESS IN_PROGRESS}</td> <td> &#8658; {@link OpCodes.Enum#UPGRADE_IN_PROGRESS_RES}
  /// from application.</td> </tr> <tr> <td>{@link ResumePostatic consts.Enum#COMMIT COMMIT}</td> <td> &#8658; {@link
  /// OpCodes.Enum#UPGRADE_COMMIT_CFM} from application.</td> </tr> </table> </dd> </dl>
  static const UPGRADE_START_CFM = 0x02;

  /// <p>To request the section of the upgrade image file bytes array expected by the board.</p>
  /// <p/>
  /// <dl> <dt><b>Content</b></dt><dd>The length and the offset of the required section from the upgrade image
  /// file.</dd> <dt><b>Previous message</b></dt><dd> <ul style="list-style-type:none"> <li>{@link
  /// OpCodes.Enum#UPGRADE_DATA UPGRADE_DATA} from application</li> <li>{@link OpCodes.Enum#UPGRADE_START_DATA_REQ
  /// UPGRADE_START_DATA_REQ} from application</li> </ul> </dd> <dt><b>Next message</b></dt><dd>{@link
  /// OpCodes.Enum#UPGRADE_DATA UPGRADE_DATA} from the application.</dd> </dl>
  static const UPGRADE_DATA_BYTES_REQ = 0x03;

  /// <p>To transfer sections of the upgrade image file to the board.</p> <dl> <dt><b>Content</b></dt><dd>The
  /// section from the upgrade file which has been requested by the Device.</dd> <dt><b>Previous
  /// message</b></dt><dd>{@link OpCodes.Enum#UPGRADE_DATA_BYTES_REQ UPGRADE_DATA_BYTES_REQ} from device.</dd>
  /// <dt><b>Next message</b></dt><dd> <ul style="list-style-type:none"> <li>{@link
  /// OpCodes.Enum#UPGRADE_IS_VALIDATION_DONE_REQ UPGRADE_IS_VALIDATION_DONE_REQ} from application.</li> <li>{@link
  /// OpCodes.Enum#UPGRADE_DATA_BYTES_REQ UPGRADE_DATA_BYTES_REQ} from device.</li> </ul> </dd> </dl>
  static const UPGRADE_DATA = 0x04;

  /// @deprecated <p>Was sent by the device.</p> <p>The device may send this message to suspend transmission of
  /// {@link Enum#UPGRADE_DATA UPGRADE_DATA} messages from the Host. This is used as flow control when the device
  /// is busy and cannot accept more data.</p>
  static const UPGRADE_SUSPEND_IND = 0x05;

  /// @deprecated <p>Was sent by device.</p> <p>If the device has sent an {@link Enum#UPGRADE_SUSPEND_IND
  /// UPGRADE_SUSPEND_IND} message to the Host it will resume transmission of {@link Enum#UPGRADE_DATA
  /// UPGRADE_DATA} messages by sending this message</p>
  static const UPGRADE_RESUME_IND = 0x06;

  /// <p>To abort the upgrade procedure.</p>
  /// <p/>
  /// <dl> <dt><b>Content</b></dt><dd>none</dd> <dt><b>Previous message</b></dt><dd>any message or none.</dd>
  /// <dt><b>Next message</b></dt><dd>{@link OpCodes.Enum#UPGRADE_ABORT_CFM UPGRADE_ABORT_CFM} from device.</dd>
  /// </dl>
  static const UPGRADE_ABORT_REQ = 0x07;

  /// <p>To confirm the abortion of the upgrade</p>
  /// <p/>
  /// <dl> <dt><b>Content</b></dt><dd>none</dd> <dt><b>Previous message</b></dt><dd>{@link
  /// OpCodes.Enum#UPGRADE_ABORT_REQ UPGRADE_ABORT_REQ} from application.</dd> <dt><b>Next
  /// message</b></dt><dd>None: disconnection of the upgrade?</dd> </dl>
  static const UPGRADE_ABORT_CFM = 0x08;

  /// @deprecated <p>Was sent by Host.</p> <p>The host can use this message to request an update on the
  /// progress of the upgrade image download. The device will respond with an {@link Enum#UPGRADE_PROGRESS_CFM
  /// UPGRADE_PROGRESS_CFM} message</p>
  static const UPGRADE_PROGRESS_REQ = 0x09;

  /// @deprecated <p>Was sent by Device.</p> <p>The device uses this message to respond to an {@link
  /// Enum#UPGRADE_PROGRESS_REQ UPGRADE_PROGRESS_REQ} message from the host. It indicates the current percentage of
  /// completion of the upgrade image file download from the host.</p>
  static const UPGRADE_PROGRESS_CFM = 0x0A;

  /// <p>To indicate the upgrade image file has successfully been received and validated.</p>
  /// <p/>
  /// <p/>
  /// <dl> <dt><b>Content</b></dt><dd>none</dd> <dt><b>Previous message</b></dt><dd>{@link
  /// OpCodes.Enum#UPGRADE_IS_VALIDATION_DONE_REQ UPGRADE_IS_VALIDATION_DONE_REQ} from application.</dd>
  /// <dt><b>Next message</b></dt><dd>{@link OpCodes.Enum#UPGRADE_TRANSFER_COMPLETE_RES
  /// UPGRADE_TRANSFER_COMPLETE_RES} from application.</dd> </dl>
  static const UPGRADE_TRANSFER_COMPLETE_IND = 0x0B;

  /// <p>To respond to the {@link OpCodes.Enum#UPGRADE_TRANSFER_COMPLETE_IND UPGRADE_TRANSFER_COMPLETE_IND} message
  /// .</p>
  /// <p/>
  /// <dl> <dt><b>Content</b></dt><dd>Contains {@link UpgradeTransferCompleteRES.Action#ABORT ABORT} or {@link
  /// UpgradeTransferCompleteRES.Action#CONTINUE CONTINUE} information.</dd> <dt><b>Previous
  /// message</b></dt><dd>{@link OpCodes.Enum#UPGRADE_TRANSFER_COMPLETE_IND UPGRADE_TRANSFER_COMPLETE_IND} from
  /// device.</dd> <dt><b>Next message</b></dt><dd>{@link OpCodes.Enum#UPGRADE_SYNC_REQ UPGRADE_SYNC_REQ} from
  /// application after the reboot of the device.</dd> </dl>
  static const UPGRADE_TRANSFER_COMPLETE_RES = 0x0C;

  /// @deprecated <p>Was sent by Device.</p> <p>Following reboot of the device to perform the upgrade, the device
  /// will reconnect to the host.</p>
  static const UPGRADE_IN_PROGRESS_IND = 0x0D;

  /// <p>To inform the Device that the Host would like to continue the upgrade process.</p>
  /// <p/>
  /// <dl> <dt><b>Content</b></dt><dd>Contains {@link UpgradeInProgressRES.Action#CONTINUE CONTINUE}
  /// information.</dd> <dt><b>Previous message</b></dt><dd>{@link OpCodes.Enum#UPGRADE_START_CFM
  /// UPGRADE_START_CFM} which should contain the Resume postatic const 3: {@link ResumePostatic consts.Enum#IN_PROGRESS
  /// IN_PROGRESS}.</dd> <dt><b>Next message</b></dt><dd>{@link OpCodes.Enum#UPGRADE_COMMIT_REQ UPGRADE_COMMIT_REQ}
  /// from the device.</dd> </dl>
  static const UPGRADE_IN_PROGRESS_RES = 0x0E;

  /// <p>Used by the board to indicate it is ready for permission to commit the upgrade.</p> <dl>
  /// <dt><b>Content</b></dt><dd>none</dd> <dt><b>Previous message</b></dt><dd>{@link
  /// OpCodes.Enum#UPGRADE_IN_PROGRESS_RES UPGRADE_IN_PROGRESS_RES} from the Host.</dd> <dt><b>Next
  /// message</b></dt><dd>{@link OpCodes.Enum#UPGRADE_COMMIT_CFM UPGRADE_COMMIT_CFM} from the Host.</dd> </dl>
  static const UPGRADE_COMMIT_REQ = 0x0F;

  /// <p>To respond to the {@link OpCodes.Enum#UPGRADE_COMMIT_REQ UPGRADE_COMMIT_REQ} message from the board.</p>
  /// <p/>
  /// <dl> <dt><b>Content</b></dt><dd>0x00 to indicate to continue the upgrade, 0x01 to abort. See {@link
  /// UpgradeCommitCFM UpgradeCommitCFM}.</dd> <dt><b>Previous message</b></dt><dd>Two possibilities:<ul><li>{@link
  /// OpCodes.Enum#UPGRADE_START_CFM UPGRADE_START_CFM} from the Device which should contain the Resume postatic const 4:
  /// {@link ResumePostatic consts.Enum#COMMIT COMMIT}.</li> <li>{@link OpCodes.Enum#UPGRADE_COMMIT_REQ UPGRADE_COMMIT_REQ}
  /// from the Device.</li></ul></dd> <dt><b>Next message</b></dt><dd>{@link OpCodes.Enum#UPGRADE_TRANSFER_COMPLETE_IND
  /// UPGRADE_TRANSFER_COMPLETE_IND} from Device.</dd> </dl>
  static const UPGRADE_COMMIT_CFM = 0x10;

  /// <p>Used by the Device to inform the application about errors or warnings. Errors are considered as fatal.
  /// Warnings are considered as informational.</p>
  /// <p/>
  /// <dl> <dt><b>Content</b></dt><dd>Contains a {@link ReturnCodes ReturnCodes}.</dd> <dt><b>Previous
  /// message</b></dt><dd>none</dd> <dt><b>Next message</b></dt><dd>depends on the Return Code and any user
  /// action.</dd> </dl>
  static const UPGRADE_ERROR_WARN_IND = 0x11;

  /// <p>Used by the board to indicate the upgrade has been completed.</p>
  /// <p/>
  /// <dl> <dt><b>Content</b></dt><dd>none</dd> <dt><b>Previous message</b></dt><dd>{@link
  /// OpCodes.Enum#UPGRADE_COMMIT_CFM UPGRADE_COMMIT_CFM} from Host.</dd> <dt><b>Next message</b></dt><dd>None,
  /// that one is the last one of a successful upgrade.</dd> </dl>
  static const UPGRADE_COMPLETE_IND = 0x12;

  /// <p>Used by the application to synchronize with the board before any other protocol message.</p>
  /// <p/>
  /// <dl> <dt><b>Content</b></dt><dd>ID of the upgrade which corresponds to the MD5 check sum of the upgrade
  /// file.</dd> <dt><b>Previous message</b></dt><dd>None, that one is the initiator of the process.</dd>
  /// <dt><b>Next message</b></dt><dd>{@link OpCodes.Enum#UPGRADE_SYNC_CFM UPGRADE_SYNC_CFM} from Device.</dd>
  /// </dl>
  static const UPGRADE_SYNC_REQ = 0x13;

  /// <p>Used by the board to respond to the {@link OpCodes.Enum#UPGRADE_SYNC_REQ UPGRADE_SYNC_REQ} message.</p>
  /// <p/>
  /// <dl> <dt><b>Content</b></dt><dd>A {@link ResumePostatic consts} value.</dd> <dt><b>Previous message</b></dt><dd>{@link
  /// OpCodes.Enum#UPGRADE_SYNC_REQ UPGRADE_START_REQ} from Device.</dd> <dt><b>Next message</b></dt><dd>{@link
  /// OpCodes.Enum#UPGRADE_START_REQ UPGRADE_START_REQ} from Device.</dd> </dl>
  static const UPGRADE_SYNC_CFM = 0x14;

  /// <p>Used by the Host to start a data transfer.</p>
  /// <p/>
  /// <dl> <dt><b>Content</b></dt><dd>none</dd> <dt><b>Previous message</b></dt><dd>{@link
  /// OpCodes.Enum#UPGRADE_START_CFM UPGRADE_START_CFM} from Device.</dd> <dt><b>Next message</b></dt><dd>{@link
  /// OpCodes.Enum#UPGRADE_DATA_static constS_REQ UPGRADE_DATA_BYTES_REQ} from Device.</dd> </dl>
  static const UPGRADE_START_DATA_REQ = 0x15;

  /// <p>Used by the Host to request for executable partition validation status.</p>
  /// <p/>
  /// <dl> <dt><b>Content</b></dt><dd>none</dd> <dt><b>Previous message</b></dt><dd>Three possibilities from
  /// Device: <ul><li>{@link OpCodes.Enum#UPGRADE_IS_VALIDATION_DONE_CFM UPGRADE_IS_VALIDATION_DONE_CFM}</li>
  /// <li>{@link OpCodes.Enum#UPGRADE_DATA UPGRADE_DATA}</li> <li>{@link OpCodes.Enum#UPGRADE_START_CFM
  /// UPGRADE_START_CFM}</li> </ul></dd> <dt><b>Next message</b></dt><dd>Two possibilities from Device:
  /// <ul><li>{@link OpCodes.Enum#UPGRADE_IS_VALIDATION_DONE_CFM UPGRADE_IS_VALIDATION_DONE_CFM}</li> <li>{@link
  /// OpCodes.Enum#UPGRADE_TRANSFER_COMPLETE_IND UPGRADE_TRANSFER_COMPLETE_IND}</li> </ul></dd> </dl>
  static const UPGRADE_IS_VALIDATION_DONE_REQ = 0x16;

  /// <p>Used by the Device to respond to the {@link OpCodes.Enum#UPGRADE_IS_VALIDATION_DONE_REQ
  /// UPGRADE_IS_VALIDATION_DONE_REQ} message.</p>
  /// <p/>
  /// <dl> <dt><b>Content</b></dt><dd>none</dd> <dt><b>Previous message</b></dt><dd>{@link
  /// OpCodes.Enum#UPGRADE_IS_VALIDATION_DONE_REQ UPGRADE_IS_VALIDATION_DONE_REQ} from Device.</dd> <dt><b>Next
  /// message</b></dt><dd>{@link OpCodes.Enum#UPGRADE_IS_VALIDATION_DONE_REQ UPGRADE_IS_VALIDATION_DONE_REQ} from
  /// Device.</dd> </dl>
  static const UPGRADE_IS_VALIDATION_DONE_CFM = 0x17;

  /// @deprecated <p>Was sent by Host.</p> <p>The Host must send this message reboot for commit.</p>
  static const UPGRADE_SYNC_AFTER_REBOOT_REQ = 0x18;

  /// <i>no documentation</i>
  static const UPGRADE_VERSION_REQ = 0x19;

  /// <i>no documentation</i>
  static const UPGRADE_VERSION_CFM = 0x1A;

  /// <i>no documentation</i>
  static const UPGRADE_VARIANT_REQ = 0x1B;

  /// <i>no documentation</i>
  static const UPGRADE_VARIANT_CFM = 0x1C;

  /// @deprecated <p>Was sent by Device.</p> <p>The device may send this message instead of {@link
  /// Enum#UPGRADE_COMMIT_REQ UPGRADE_COMMIT_REQ} (it depends on file content).</p>
  static const UPGRADE_ERASE_SQIF_REQ = 0x1D;

  /// @deprecated <p>Was sent by Host.</p> <p>The host must respond to the {@link Enum#UPGRADE_ERASE_SQIF_REQ
  /// UPGRADE_ERASE_SQIF_REQ} message from the device with this message.</p>
  static const UPGRADE_ERASE_SQIF_CFM = 0x1E;

  /// <p>Used by the Host to confirm it received an error or a warning message from the board.</p>
  /// <p/>
  /// <dl> <dt><b>Content</b></dt><dd>The {@link ReturnCodes ReturnCodes} received.</dd> <dt><b>Previous
  /// message</b></dt><dd>{@link OpCodes.Enum#UPGRADE_ERROR_WARN_IND UPGRADE_ERROR_WARN_IND} from Device.</dd>
  /// <dt><b>Next message</b></dt><dd>Depends on the received {@link ReturnCodes ReturnCodes} value.</dd> </dl>
  static const UPGRADE_ERROR_WARN_RES = 0x1F;


  /**
   * <p>The number of bytes which contains the number of bytes of the uploading file to send.</p>
   */
   static const NB_BYTES_LENGTH = 4;
  /**
   * <p>The offset in the {@link Enum#UPGRADE_DATA_BYTES_REQ UPGRADE_DATA_BYTES_REQ} bytes data where the "number
   * of bytes to send" information starts.</p>
   */
  static const NB_BYTES_OFFSET = 0;
  /**
   * <p>The number of bytes which contains the byte offset within the upgrade file from which the host should
   * start transferring data to the device.</p>
   */
  static const FILE_OFFSET_LENGTH = 4;
  /**
   * <p>The offset in the {@link Enum#UPGRADE_DATA_BYTES_REQ UPGRADE_DATA_BYTES_REQ} bytes data where the file
   * offset information starts. .</p>
   */
  static const FILE_OFFSET_OFFSET = NB_BYTES_OFFSET + NB_BYTES_LENGTH;
  /**
   * The length for the data of the {@link Enum#UPGRADE_DATA_BYTES_REQ UPGRADE_DATA_BYTES_REQ} message.
   */
  static const DATA_LENGTH = FILE_OFFSET_LENGTH + NB_BYTES_LENGTH;
}

"""Regression contracts for real-device capture and MediaTek bring-up.

Run with ``python tools/test_capture_contract.py``. These are source-level
checks because the Windows hardware APIs cannot be exercised on the Linux CI
runner; the Windows self-test continues to cover the simulated wire protocol.
"""
from pathlib import Path
import unittest

DEVICE_SETUP_DIR = Path(__file__).resolve().parent.parent


class CaptureTransportContractTests(unittest.TestCase):
    def test_usb_scan_includes_com_port_child_device_nodes(self):
        source = (DEVICE_SETUP_DIR / "UsbDetect.pas").read_text(encoding="utf-8")
        self.assertIn(
            "SetupDiGetClassDevsW(nil, nil, 0,\n    DIGCF_PRESENT or DIGCF_ALLCLASSES)",
            source,
        )
        self.assertIn("child under Ports (COM & LPT)", source)
        self.assertNotIn("Enumerator := 'USB'", source)

    def test_capture_waits_for_a_vcom_child_after_vid_pid_parent_appears(self):
        source = (DEVICE_SETUP_DIR / "DevCapture.pas").read_text(encoding="utf-8")
        start = source.index("function TDeviceCapture.WaitForDevice")
        end = source.index("procedure TDeviceCapture.Release", start)
        wait = source[start:end]
        self.assertIn("CComPortEnumerationGraceMs = 3000", wait)
        self.assertIn("if (Grab.PortName <> '') or Grab.Simulated then", wait)
        self.assertIn("TicksSince(PortlessAt) >= CComPortEnumerationGraceMs", wait)
        self.assertIn("waiting for its COM/VCOM port", wait)
        self.assertIn("No COM/VCOM interface appeared within", wait)

    def test_generic_mtk_vid_is_not_accepted_as_a_service_mode(self):
        source = (DEVICE_SETUP_DIR / "DevCapture.pas").read_text(encoding="utf-8")
        self.assertIn("dpMtk: Result := 'BROM,PRELOADER,DA,META';", source)
        self.assertIn("MTK is only the generic VID_0E8D fallback", source)

    def test_release_does_not_leave_a_stale_device_candidate(self):
        source = (DEVICE_SETUP_DIR / "DevCapture.pas").read_text(encoding="utf-8")
        release = source[source.index("procedure TDeviceCapture.Release;"):]
        self.assertIn("FHaveDevice := False;", release)
        self.assertIn("FDevice.VidPid := '';", release)
        self.assertIn("if FLocked then", source)
        self.assertNotIn("if FLocked or (FHaveDevice and not FSimulated) then", source)

    def test_vid_pid_only_is_never_mislabeled_as_an_exclusive_lock(self):
        source = (DEVICE_SETUP_DIR / "DeviceSession.pas").read_text(encoding="utf-8")
        self.assertIn("VID/PID detection alone is", source)
        self.assertIn("not a device lock", source)
        self.assertIn("raw USB bind through the bundled libusb", source)

        start = source.index("function TDeviceSession.OpenMtk")
        end = source.index("function TDeviceSession.OpenComPlatform", start)
        mtk_open = source[start:end]
        self.assertLess(
            mtk_open.index("MissingTransportMessage(FGrab.Device)"),
            mtk_open.index("FStage := ssLocked"),
        )
        self.assertIn("not FCapture.Locked", mtk_open)

    def test_xflash_is_rejected_before_auth_or_upload(self):
        source = (DEVICE_SETUP_DIR / "DeviceSession.pas").read_text(encoding="utf-8")
        start = source.index("function TDeviceSession.BootDa")
        end = source.index("function TDeviceSession.OpenMtk", start)
        boot_da = source[start:end]
        self.assertIn("hwcode $", boot_da)
        self.assertIn("compatible XFLASH/XML implementation", boot_da)
        self.assertLess(boot_da.index("if ChipMode <> dmLegacy"),
                        boot_da.index("if not LoadAuth"))
        self.assertLess(boot_da.index("Da.LoadFromFile"),
                        boot_da.index("if not LoadAuth"))
        self.assertLess(boot_da.index("FBrom.SendAuth"),
                        boot_da.index("FBrom.SendDa"))

    def test_read_flash_info_button_is_wired_to_mtk_da_bringup(self):
        main = (DEVICE_SETUP_DIR / "Main2Form.pas").read_text(encoding="utf-8")
        engine = (DEVICE_SETUP_DIR / "JobEngine.pas").read_text(encoding="utf-8")
        session = (DEVICE_SETUP_DIR / "DeviceSession.pas").read_text(encoding="utf-8")
        button = main[main.index("procedure TMain2Form.btnReadInfoClick"):]
        self.assertIn("StartJob(jkReadFlashInfo);", button)
        self.assertIn("jkReadFlashInfo", engine)
        self.assertIn("if JobNeedsDa(AKind) then\n      Result := coBootloader", engine)
        self.assertIn("Result := OpenMtk(ANeed, ADaFile, AAuthFile, AScatFile);", session)
        self.assertIn("Result := BootDa(ADaFile, AAuthFile);", session)

    def test_opaque_vendor_da_tooltip_explains_it_cannot_be_uploaded_as_is(self):
        source = (DEVICE_SETUP_DIR / "DaLoader.pas").read_text(encoding="utf-8")
        self.assertIn("opaque vendor container, not a plaintext DA", source)
        self.assertIn("this build cannot decode", source)
        self.assertIn("or upload it as-is", source)

    def test_portless_mtk_device_is_bound_over_raw_usb(self):
        capture = (DEVICE_SETUP_DIR / "DevCapture.pas").read_text(encoding="utf-8")
        usbraw = (DEVICE_SETUP_DIR / "UsbRaw.pas").read_text(encoding="utf-8")
        session = (DEVICE_SETUP_DIR / "DeviceSession.pas").read_text(encoding="utf-8")

        # The transport is a drop-in TCommTransport: the existing BROM
        # handshake and DA read/flash stack run over it unchanged.
        self.assertIn("TUsbTransport = class(TCommTransport)", usbraw)
        self.assertIn(
            "function OpenPort(out AError: string): Boolean; override;", usbraw
        )
        self.assertIn(
            "function WriteData(const AData; ACount: Integer): Integer; override;",
            usbraw,
        )
        self.assertIn(
            "function ReadData(var ABuffer; ACount, ATimeoutMs: Integer): Integer;",
            usbraw,
        )

        # Detect -> bind -> endpoints: the mtkclient connect() flow.
        self.assertIn("libusb_get_device_list", usbraw)
        self.assertIn("libusb_claim_interface", usbraw)
        self.assertIn("libusb_bulk_transfer", usbraw)
        self.assertIn("libusb_detach_kernel_driver", usbraw)

        # Capture tries the raw USB bind for a portless MediaTek device only,
        # and takes the lock only after a successful claim.
        poll = capture[
            capture.index("function TDeviceCapture.PollOnce"): capture.index(
                "function TDeviceCapture.WaitForDevice"
            )
        ]
        self.assertIn(
            "if (APlatform = dpMtk) and TryUsbBind(Devs[I], AGrab, Err) then",
            poll,
        )
        self.assertIn("FLocked := True;", poll)

        bind = capture[
            capture.index("function TDeviceCapture.TryUsbBind"): capture.index(
                "function TDeviceCapture.PollOnce"
            )
        ]
        self.assertIn("Usb.OpenPort(AError)", bind)
        self.assertLess(
            bind.index("FTransport := Usb;"), bind.index("AGrab.Found := True;")
        )
        # Bind attempts are throttled and the throttle resets on Release.
        self.assertIn("TicksSince(FUsbLastAt) < 1000", bind)
        self.assertIn("FUsbLastVidPid := '';", capture)

        # The session reports the USB claim as the lock, and detection alone
        # is still never a lock.
        self.assertIn("is now claimed exclusively", session)
        self.assertIn("FTransport is TUsbTransport", session)

        # The grace-period error still names the missing COM port and adds
        # the raw USB failure reason.
        wait = capture[
            capture.index("function TDeviceCapture.WaitForDevice"): capture.index(
                "procedure TDeviceCapture.Release"
            )
        ]
        self.assertIn("No COM/VCOM interface appeared within", wait)
        self.assertIn("Raw USB bind also failed: ", wait)


if __name__ == "__main__":
    unittest.main(verbosity=2)

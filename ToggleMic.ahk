; FROM https://www.autohotkey.com/boards/viewtopic.php?t=67431
; and https://www.autohotkey.com/boards/viewtopic.php?t=49980

;INTERFACE - IMMDeviceEnumerator
;source: mmdeviceapi.h
; 0 IUnknown::QueryInterface
; 1 IUnknown::AddRef
; 2 IUnknown::Release
; 3 IMMDeviceEnumerator::EnumAudioEndpoints
; 4 IMMDeviceEnumerator::GetDefaultAudioEndpoint
; 5 IMMDeviceEnumerator::GetDevice
; 6 IMMDeviceEnumerator::RegisterEndpointNotificationCallback
; 7 IMMDeviceEnumerator::UnregisterEndpointNotificationCallback

;INTERFACE - IMMDevice
;source: mmdeviceapi.h
; 0 IUnknown::QueryInterface
; 1 IUnknown::AddRef
; 2 IUnknown::Release
; 3 IMMDevice::Activate
; 4 IMMDevice::OpenPropertyStore
; 5 IMMDevice::GetId
; 6 IMMDevice::GetState

;INTERFACE - IAudioEndpointVolume
;source: endpointvolume.h
; 0 IUnknown::QueryInterface
; 1 IUnknown::AddRef
; 2 IUnknown::Release
; 3 IAudioEndpointVolume::RegisterControlChangeNotify
; 4 IAudioEndpointVolume::UnregisterControlChangeNotify
; 5 IAudioEndpointVolume::GetChannelCount
; 6 IAudioEndpointVolume::SetMasterVolumeLevel
; 7 IAudioEndpointVolume::SetMasterVolumeLevelScalar
; 8 IAudioEndpointVolume::GetMasterVolumeLevel
; 9 IAudioEndpointVolume::GetMasterVolumeLevelScalar
;10 IAudioEndpointVolume::SetChannelVolumeLevel
;11 IAudioEndpointVolume::SetChannelVolumeLevelScalar
;12 IAudioEndpointVolume::GetChannelVolumeLevel
;13 IAudioEndpointVolume::GetChannelVolumeLevelScalar
;14 IAudioEndpointVolume::SetMute
;15 IAudioEndpointVolume::GetMute
;16 IAudioEndpointVolume::GetVolumeStepInfo
;17 IAudioEndpointVolume::VolumeStepUp
;18 IAudioEndpointVolume::VolumeStepDown
;19 IAudioEndpointVolume::QueryHardwareSupport
;20 IAudioEndpointVolume::GetVolumeRange

do_microphone_mute(mute)
{
    static EDataFlow_eRender := 0
    static EDataFlow_eCapture := 1
    static EDataFlow_eAll := 2
    static ERole_eConsole := 0
    static ERole_eMultimedia := 1
    static ERole_eCommunications := 2
    static CLSCTX_ALL := 0x17 ; /*CLSCTX_INPROC_SERVER*/1 | /*CLSCTX_INPROC_HANDLER*/2 | /*CLSCTX_LOCAL_SERVER*/4 | /*CLSCTX_REMOTE_SERVER*/16;

    IMMDeviceEnumerator := ComObject("{BCDE0395-E52F-467C-8E3D-C4579291692E}", "{A95664D2-9614-4F35-A746-DE8DB63617E6}")
    if (IMMDeviceEnumerator == 0) {
      MsgBox("failed to create device enumerator")
      goto out
    }

    ; 4 IMMDeviceEnumerator::GetDefaultAudioEndpoint
    ret := ComCall(4, IMMDeviceEnumerator, "UInt", EDataFlow_eCapture, "UInt", ERole_eCommunications, "UPtrP", &IMMDevice:=0)
    msg(Format("GetDefaultAudioEndpoint ret = {:#x}, IMMDevice = {:#x}", ret, IMMDevice))

    ; interface ID to get audio endpoint volume control
    IAudioEndPointVolume_IID := Buffer(16)
    DllCall("ole32\CLSIDFromString", "wstr", "{5CDF2C82-841E-4546-9722-0CF74078229A}", "UPtr", IAudioEndPointVolume_IID.ptr)

    ; 3 IMMDevice::Activate
    ret := ComCall(3, IMMDevice, "Ptr", IAudioEndPointVolume_IID.ptr, "UInt", CLSCTX_ALL, "UInt", 0, "UPtrP", &IAudioEndPointVolume:=0)
    if (IAudioEndpointVolume == 0) {
      MsgBox("failed to create audio endpoint volume")
      goto out
    }

    ; Set volume to 0, otherwise it's hard to get feedback that the global mute
    ; is actually applied
    if (mute)
      vol := 0.0
    else
      vol := 1.0

    ; 7 IAudioEndpointVolume::SetMasterVolumeLevelScalar
    ret := ComCall(7, IAudioEndpointVolume, "Float", vol, "Ptr", 0)
    msg(Format("SetMasterVolumeLevelScalar {:.1f} ret = {:u}", vol, ret))

    ; 14 IAudioEndpointVolume::SetMute
    ret := ComCall(14, IAudioEndpointVolume, "UInt", mute, "Ptr", 0)
    msg(Format("SetMute {:u} ret = {:u}", mute, ret))

out:
    if (IAudioEndpointVolume)
      ObjRelease(IAudioEndpointVolume)
}

// HOPE - registro visual del dolor neuropatico cronico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.
//
// Codificacion de video MP4 (H.264) con Media Foundation, que incluye
// Windows 10 y 11 (las ediciones "N" necesitan el Media Feature Pack).

#include "hope_media_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <codecapi.h>
#include <mfapi.h>
#include <mferror.h>
#include <mfidl.h>
#include <mfreadwrite.h>
#include <wrl/client.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <cstdint>
#include <memory>
#include <sstream>
#include <string>
#include <vector>

namespace hope_media {

using Microsoft::WRL::ComPtr;

namespace {

std::wstring Utf8ToWide(const std::string& text) {
  if (text.empty()) {
    return std::wstring();
  }
  const int size = MultiByteToWideChar(CP_UTF8, 0, text.c_str(),
                                       static_cast<int>(text.size()), nullptr, 0);
  std::wstring wide(static_cast<size_t>(size), L'\0');
  MultiByteToWideChar(CP_UTF8, 0, text.c_str(), static_cast<int>(text.size()),
                      wide.data(), size);
  return wide;
}

std::string HrMessage(const char* what, HRESULT hr) {
  std::ostringstream out;
  out << what << " (0x" << std::hex << static_cast<unsigned long>(hr) << ")";
  return out.str();
}

const flutter::EncodableValue* Arg(const flutter::EncodableMap* map,
                                   const char* key) {
  if (map == nullptr) {
    return nullptr;
  }
  auto it = map->find(flutter::EncodableValue(key));
  return it == map->end() ? nullptr : &it->second;
}

int64_t IntArg(const flutter::EncodableMap* map, const char* key,
               int64_t fallback) {
  const flutter::EncodableValue* value = Arg(map, key);
  if (value == nullptr) {
    return fallback;
  }
  if (const int32_t* i = std::get_if<int32_t>(value)) {
    return *i;
  }
  if (const int64_t* l = std::get_if<int64_t>(value)) {
    return *l;
  }
  return fallback;
}

// Media Foundation se carga en diferido (CMakeLists.txt): si falta, como en
// las ediciones "N" de Windows sin el Media Feature Pack, la app arranca igual
// y el video se sustituye por el GIF.
bool MediaFoundationPresent() {
  static const bool present = [] {
    const HMODULE plat =
        LoadLibraryExW(L"mfplat.dll", nullptr, LOAD_LIBRARY_SEARCH_SYSTEM32);
    const HMODULE readwrite =
        LoadLibraryExW(L"mfreadwrite.dll", nullptr, LOAD_LIBRARY_SEARCH_SYSTEM32);
    return plat != nullptr && readwrite != nullptr;
  }();
  return present;
}

// Hay algun codificador H.264 en este equipo?
bool IsH264Available() {
  if (!MediaFoundationPresent()) {
    return false;
  }
  if (FAILED(MFStartup(MF_VERSION))) {
    return false;
  }
  MFT_REGISTER_TYPE_INFO info = {MFMediaType_Video, MFVideoFormat_H264};
  IMFActivate** activates = nullptr;
  UINT32 count = 0;
  const HRESULT hr = MFTEnumEx(
      MFT_CATEGORY_VIDEO_ENCODER,
      MFT_ENUM_FLAG_SYNCMFT | MFT_ENUM_FLAG_ASYNCMFT | MFT_ENUM_FLAG_HARDWARE |
          MFT_ENUM_FLAG_SORTANDFILTER,
      nullptr, &info, &activates, &count);
  if (SUCCEEDED(hr) && activates != nullptr) {
    for (UINT32 i = 0; i < count; ++i) {
      activates[i]->Release();
    }
    CoTaskMemFree(activates);
  }
  MFShutdown();
  return SUCCEEDED(hr) && count > 0;
}

// Paso de una imagen RGB32 segun su tipo (negativo si va de abajo arriba).
LONG DefaultStride(IMFMediaType* type, UINT32 width) {
  UINT32 stride = 0;
  if (SUCCEEDED(type->GetUINT32(MF_MT_DEFAULT_STRIDE, &stride))) {
    return static_cast<LONG>(stride);
  }
  LONG computed = 0;
  if (SUCCEEDED(MFGetStrideForBitmapInfoHeader(MFVideoFormat_RGB32.Data1, width,
                                               &computed))) {
    return computed;
  }
  return static_cast<LONG>(width * 4);
}

// Color ARGB (como en Android) de dos puntos del primer fotograma.
void ReadColors(IMFSample* sample, IMFMediaType* type, UINT32 width,
                UINT32 height, flutter::EncodableMap* out) {
  ComPtr<IMFMediaBuffer> buffer;
  if (FAILED(sample->ConvertToContiguousBuffer(&buffer))) {
    return;
  }
  ComPtr<IMF2DBuffer> buffer2d;
  BYTE* scan0 = nullptr;
  LONG pitch = 0;
  bool locked2d = false;
  if (SUCCEEDED(buffer.As(&buffer2d)) &&
      SUCCEEDED(buffer2d->Lock2D(&scan0, &pitch))) {
    locked2d = true;
  } else {
    BYTE* data = nullptr;
    DWORD length = 0;
    if (FAILED(buffer->Lock(&data, nullptr, &length))) {
      return;
    }
    pitch = DefaultStride(type, width);
    scan0 = pitch < 0 ? data + static_cast<size_t>(-pitch) * (height - 1) : data;
  }
  auto pixel = [scan0, pitch](UINT32 x, UINT32 y) {
    const BYTE* p = scan0 + static_cast<ptrdiff_t>(y) * pitch +
                    static_cast<ptrdiff_t>(x) * 4;
    return static_cast<int64_t>(0xFF000000LL | (static_cast<int64_t>(p[2]) << 16) |
                                (static_cast<int64_t>(p[1]) << 8) |
                                static_cast<int64_t>(p[0]));
  };
  (*out)[flutter::EncodableValue("topColor")] =
      flutter::EncodableValue(pixel(width / 2, height / 6));
  (*out)[flutter::EncodableValue("bottomColor")] =
      flutter::EncodableValue(pixel(width / 2, height * 5 / 6));
  if (locked2d) {
    buffer2d->Unlock2D();
  } else {
    buffer->Unlock();
  }
}

// Datos de un video: tamano, duracion, fotogramas y colores del primero.
flutter::EncodableMap ProbeVideo(const std::wstring& path) {
  flutter::EncodableMap out;
  if (!MediaFoundationPresent() || FAILED(MFStartup(MF_VERSION))) {
    return out;
  }
  {
    const DWORD video = static_cast<DWORD>(MF_SOURCE_READER_FIRST_VIDEO_STREAM);
    ComPtr<IMFAttributes> attributes;
    HRESULT hr = MFCreateAttributes(&attributes, 1);
    if (SUCCEEDED(hr)) {
      hr = attributes->SetUINT32(MF_SOURCE_READER_ENABLE_VIDEO_PROCESSING, TRUE);
    }
    ComPtr<IMFSourceReader> reader;
    if (SUCCEEDED(hr)) {
      hr = MFCreateSourceReaderFromURL(path.c_str(), attributes.Get(), &reader);
    }
    ComPtr<IMFMediaType> wanted;
    if (SUCCEEDED(hr)) hr = MFCreateMediaType(&wanted);
    if (SUCCEEDED(hr)) hr = wanted->SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Video);
    if (SUCCEEDED(hr)) hr = wanted->SetGUID(MF_MT_SUBTYPE, MFVideoFormat_RGB32);
    if (SUCCEEDED(hr)) hr = reader->SetCurrentMediaType(video, nullptr, wanted.Get());
    ComPtr<IMFMediaType> current;
    if (SUCCEEDED(hr)) hr = reader->GetCurrentMediaType(video, &current);
    UINT32 width = 0;
    UINT32 height = 0;
    if (SUCCEEDED(hr)) hr = MFGetAttributeSize(current.Get(), MF_MT_FRAME_SIZE, &width, &height);
    if (SUCCEEDED(hr)) {
      out[flutter::EncodableValue("width")] =
          flutter::EncodableValue(static_cast<int32_t>(width));
      out[flutter::EncodableValue("height")] =
          flutter::EncodableValue(static_cast<int32_t>(height));
      PROPVARIANT duration;
      PropVariantInit(&duration);
      if (SUCCEEDED(reader->GetPresentationAttribute(
              static_cast<DWORD>(MF_SOURCE_READER_MEDIASOURCE), MF_PD_DURATION,
              &duration))) {
        out[flutter::EncodableValue("durationMs")] = flutter::EncodableValue(
            static_cast<int64_t>(duration.uhVal.QuadPart / 10000));
        PropVariantClear(&duration);
      }
      int32_t frames = 0;
      for (;;) {
        DWORD flags = 0;
        LONGLONG time = 0;
        ComPtr<IMFSample> sample;
        if (FAILED(reader->ReadSample(video, 0, nullptr, &flags, &time, &sample))) {
          break;
        }
        if ((flags & static_cast<DWORD>(MF_SOURCE_READERF_ENDOFSTREAM)) != 0) {
          break;
        }
        if (!sample) {
          continue;
        }
        if (frames == 0) {
          ReadColors(sample.Get(), current.Get(), width, height, &out);
        }
        ++frames;
      }
      out[flutter::EncodableValue("frames")] = flutter::EncodableValue(frames);
    }
  }
  MFShutdown();
  return out;
}

}  // namespace

// Escribe un MP4 a partir de fotogramas RGBA (de arriba abajo).
class Mp4Writer {
 public:
  Mp4Writer() = default;

  ~Mp4Writer() {
    writer_.Reset();
    if (mf_started_) {
      MFShutdown();
    }
  }

  Mp4Writer(const Mp4Writer&) = delete;
  Mp4Writer& operator=(const Mp4Writer&) = delete;

  HRESULT Start(const std::wstring& path, UINT32 width, UINT32 height,
                UINT32 fps, UINT32 bitrate) {
    if (!MediaFoundationPresent()) {
      return E_NOTIMPL;
    }
    HRESULT hr = MFStartup(MF_VERSION);
    if (FAILED(hr)) {
      return hr;
    }
    mf_started_ = true;
    path_ = path;
    width_ = width;
    height_ = height;
    fps_ = fps == 0 ? 30 : fps;

    hr = MFCreateSinkWriterFromURL(path.c_str(), nullptr, nullptr, &writer_);

    ComPtr<IMFMediaType> out_type;
    if (SUCCEEDED(hr)) hr = MFCreateMediaType(&out_type);
    if (SUCCEEDED(hr)) hr = out_type->SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Video);
    if (SUCCEEDED(hr)) hr = out_type->SetGUID(MF_MT_SUBTYPE, MFVideoFormat_H264);
    if (SUCCEEDED(hr)) hr = out_type->SetUINT32(MF_MT_AVG_BITRATE, bitrate);
    if (SUCCEEDED(hr)) {
      hr = out_type->SetUINT32(MF_MT_INTERLACE_MODE, MFVideoInterlace_Progressive);
    }
    if (SUCCEEDED(hr)) {
      hr = out_type->SetUINT32(MF_MT_MPEG2_PROFILE, eAVEncH264VProfile_Main);
    }
    if (SUCCEEDED(hr)) hr = MFSetAttributeSize(out_type.Get(), MF_MT_FRAME_SIZE, width, height);
    if (SUCCEEDED(hr)) hr = MFSetAttributeRatio(out_type.Get(), MF_MT_FRAME_RATE, fps_, 1);
    if (SUCCEEDED(hr)) hr = MFSetAttributeRatio(out_type.Get(), MF_MT_PIXEL_ASPECT_RATIO, 1, 1);
    if (SUCCEEDED(hr)) hr = writer_->AddStream(out_type.Get(), &stream_);

    ComPtr<IMFMediaType> in_type;
    if (SUCCEEDED(hr)) hr = MFCreateMediaType(&in_type);
    if (SUCCEEDED(hr)) hr = in_type->SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Video);
    if (SUCCEEDED(hr)) hr = in_type->SetGUID(MF_MT_SUBTYPE, MFVideoFormat_RGB32);
    if (SUCCEEDED(hr)) {
      hr = in_type->SetUINT32(MF_MT_INTERLACE_MODE, MFVideoInterlace_Progressive);
    }
    // Paso positivo: las filas van de arriba abajo.
    if (SUCCEEDED(hr)) hr = in_type->SetUINT32(MF_MT_DEFAULT_STRIDE, width * 4);
    if (SUCCEEDED(hr)) hr = MFSetAttributeSize(in_type.Get(), MF_MT_FRAME_SIZE, width, height);
    if (SUCCEEDED(hr)) hr = MFSetAttributeRatio(in_type.Get(), MF_MT_FRAME_RATE, fps_, 1);
    if (SUCCEEDED(hr)) hr = MFSetAttributeRatio(in_type.Get(), MF_MT_PIXEL_ASPECT_RATIO, 1, 1);
    if (SUCCEEDED(hr)) hr = writer_->SetInputMediaType(stream_, in_type.Get(), nullptr);
    if (SUCCEEDED(hr)) hr = writer_->BeginWriting();
    return hr;
  }

  HRESULT AddFrame(const uint8_t* rgba, size_t size) {
    if (!writer_) {
      return E_UNEXPECTED;
    }
    const DWORD stride = width_ * 4;
    const DWORD bytes = stride * height_;
    if (size < static_cast<size_t>(bytes)) {
      return E_INVALIDARG;
    }
    ComPtr<IMFMediaBuffer> buffer;
    HRESULT hr = MFCreateMemoryBuffer(bytes, &buffer);
    BYTE* data = nullptr;
    if (SUCCEEDED(hr)) hr = buffer->Lock(&data, nullptr, nullptr);
    if (SUCCEEDED(hr)) {
      // RGBA -> BGRA (formato RGB32 de Media Foundation).
      for (UINT32 y = 0; y < height_; ++y) {
        const uint8_t* src = rgba + static_cast<size_t>(y) * stride;
        BYTE* dst = data + static_cast<size_t>(y) * stride;
        for (UINT32 x = 0; x < width_; ++x) {
          const size_t o = static_cast<size_t>(x) * 4;
          dst[o + 0] = src[o + 2];
          dst[o + 1] = src[o + 1];
          dst[o + 2] = src[o + 0];
          dst[o + 3] = 255;
        }
      }
      buffer->Unlock();
      hr = buffer->SetCurrentLength(bytes);
    }
    ComPtr<IMFSample> sample;
    if (SUCCEEDED(hr)) hr = MFCreateSample(&sample);
    if (SUCCEEDED(hr)) hr = sample->AddBuffer(buffer.Get());
    const LONGLONG duration = 10000000LL / static_cast<LONGLONG>(fps_);
    if (SUCCEEDED(hr)) hr = sample->SetSampleTime(frame_ * duration);
    if (SUCCEEDED(hr)) hr = sample->SetSampleDuration(duration);
    if (SUCCEEDED(hr)) hr = writer_->WriteSample(stream_, sample.Get());
    if (SUCCEEDED(hr)) {
      ++frame_;
    }
    return hr;
  }

  HRESULT Finish() {
    if (!writer_) {
      return E_UNEXPECTED;
    }
    const HRESULT hr = writer_->Finalize();
    writer_.Reset();
    return hr;
  }

  // Descarta el video a medias.
  void Cancel() {
    writer_.Reset();
    if (!path_.empty()) {
      DeleteFileW(path_.c_str());
    }
  }

 private:
  ComPtr<IMFSinkWriter> writer_;
  std::wstring path_;
  DWORD stream_ = 0;
  UINT32 width_ = 0;
  UINT32 height_ = 0;
  UINT32 fps_ = 30;
  LONGLONG frame_ = 0;
  bool mf_started_ = false;
};

// static
void HopeMediaPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "hope_media",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<HopeMediaPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

HopeMediaPlugin::HopeMediaPlugin() {}

HopeMediaPlugin::~HopeMediaPlugin() {}

void HopeMediaPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string& method = method_call.method_name();
  const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments());

  if (method == "isSupported") {
    result->Success(flutter::EncodableValue(IsH264Available()));
    return;
  }

  if (method == "start") {
    const flutter::EncodableValue* path_value = Arg(args, "path");
    const std::string* path =
        path_value == nullptr ? nullptr : std::get_if<std::string>(path_value);
    if (path == nullptr) {
      result->Error("hope_media", "Falta la ruta del video");
      return;
    }
    auto writer = std::make_unique<Mp4Writer>();
    const HRESULT hr = writer->Start(
        Utf8ToWide(*path), static_cast<UINT32>(IntArg(args, "width", 720)),
        static_cast<UINT32>(IntArg(args, "height", 1280)),
        static_cast<UINT32>(IntArg(args, "fps", 30)),
        static_cast<UINT32>(IntArg(args, "bitRate", 2000000)));
    if (FAILED(hr)) {
      result->Error("hope_media", HrMessage("No se pudo iniciar el video", hr));
      return;
    }
    writer_ = std::move(writer);
    result->Success();
    return;
  }

  if (method == "addFrame") {
    const flutter::EncodableValue* value = Arg(args, "rgba");
    const std::vector<uint8_t>* rgba =
        value == nullptr ? nullptr : std::get_if<std::vector<uint8_t>>(value);
    if (!writer_ || rgba == nullptr) {
      result->Error("hope_media", "El video no se ha iniciado");
      return;
    }
    const HRESULT hr = writer_->AddFrame(rgba->data(), rgba->size());
    if (FAILED(hr)) {
      writer_->Cancel();
      writer_.reset();
      result->Error("hope_media", HrMessage("No se pudo anadir el fotograma", hr));
      return;
    }
    result->Success();
    return;
  }

  if (method == "finish") {
    if (!writer_) {
      result->Error("hope_media", "El video no se ha iniciado");
      return;
    }
    const HRESULT hr = writer_->Finish();
    writer_.reset();
    if (FAILED(hr)) {
      result->Error("hope_media", HrMessage("No se pudo cerrar el video", hr));
      return;
    }
    result->Success();
    return;
  }

  if (method == "cancel") {
    if (writer_) {
      writer_->Cancel();
    }
    writer_.reset();
    result->Success();
    return;
  }

  if (method == "probe") {
    const flutter::EncodableValue* path_value = Arg(args, "path");
    const std::string* path =
        path_value == nullptr ? nullptr : std::get_if<std::string>(path_value);
    if (path == nullptr) {
      result->Error("hope_media", "Falta la ruta");
      return;
    }
    flutter::EncodableMap info = ProbeVideo(Utf8ToWide(*path));
    WIN32_FILE_ATTRIBUTE_DATA attributes;
    if (GetFileAttributesExW(Utf8ToWide(*path).c_str(), GetFileExInfoStandard,
                             &attributes)) {
      const int64_t bytes =
          (static_cast<int64_t>(attributes.nFileSizeHigh) << 32) |
          static_cast<int64_t>(attributes.nFileSizeLow);
      info[flutter::EncodableValue("bytes")] = flutter::EncodableValue(bytes);
    }
    result->Success(flutter::EncodableValue(info));
    return;
  }

  result->NotImplemented();
}

}  // namespace hope_media

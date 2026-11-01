// HOPE - registro visual del dolor neuropatico cronico.
// Copyright (C) 2026 joseiraburu y colaboradores. Licencia GPL-3.0-or-later.

#ifndef FLUTTER_PLUGIN_HOPE_MEDIA_PLUGIN_H_
#define FLUTTER_PLUGIN_HOPE_MEDIA_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace hope_media {

class Mp4Writer;

// Codifica videos MP4 (H.264) con Media Foundation, incluido en Windows.
class HopeMediaPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  HopeMediaPlugin();

  virtual ~HopeMediaPlugin();

  // Disallow copy and assign.
  HopeMediaPlugin(const HopeMediaPlugin&) = delete;
  HopeMediaPlugin& operator=(const HopeMediaPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

 private:
  std::unique_ptr<Mp4Writer> writer_;
};

}  // namespace hope_media

#endif  // FLUTTER_PLUGIN_HOPE_MEDIA_PLUGIN_H_

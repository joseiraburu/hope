#include "include/hope_media/hope_media_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "hope_media_plugin.h"

void HopeMediaPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  hope_media::HopeMediaPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

# Complemento de video de HOPE (Media Foundation).
#
# Basado en la plantilla de complementos de Flutter. Media Foundation se
# carga en diferido para que la app arranque tambien en las ediciones "N" de
# Windows, que no lo incluyen.
cmake_minimum_required(VERSION 3.14)

set(PROJECT_NAME "hope_media")
project(${PROJECT_NAME} LANGUAGES CXX)

cmake_policy(VERSION 3.14...3.25)

# Este nombre lo usa Flutter al compilar; no debe cambiarse.
set(PLUGIN_NAME "hope_media_plugin")

list(APPEND PLUGIN_SOURCES
  "hope_media_plugin.cpp"
  "hope_media_plugin.h"
)

add_library(${PLUGIN_NAME} SHARED
  "include/hope_media/hope_media_plugin_c_api.h"
  "hope_media_plugin_c_api.cpp"
  ${PLUGIN_SOURCES}
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin
  mfplat mfreadwrite mfuuid delayimp)
target_link_options(${PLUGIN_NAME} PRIVATE
  "/DELAYLOAD:mfplat.dll" "/DELAYLOAD:mfreadwrite.dll")

set(hope_media_bundled_libraries
  ""
  PARENT_SCOPE
)

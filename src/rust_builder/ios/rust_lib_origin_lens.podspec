#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint rust_lib_origin_lens.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'rust_lib_origin_lens'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter FFI plugin project.'
  s.description      = <<-DESC
A new Flutter FFI plugin project.
                       DESC
  s.homepage         = 'https://github.com/aloth/origin-lens'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Alexander Loth and Dominique Conceicao Rosario' => 'support+originlens@alexloth.com' }

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support://
  # having a separate set of source files per platform.
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.swift_version = '5.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }

  s.script_phase = {
    :name => 'Build Rust library',
    # rust folder is now at ../rust relative to ios folder (inside rust_builder)
    :script => 'sh "$PODS_TARGET_SRCROOT/../cargokit/build_pod.sh" ../rust rust_lib_origin_lens',
    :execution_position => :before_compile,
    :input_files => ['${BUILT_PRODUCTS_DIR}/cargokit_phony'],
    # Let XCode know that the static library will be located in the build directory
    :output_files => ['${BUILT_PRODUCTS_DIR}/librust_lib_origin_lens.a'],
  }
  # Add the static library as a vendored library
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    # Flutter.framework does not contain a i386 slice.
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'OTHER_LDFLAGS' => '-force_load ${BUILT_PRODUCTS_DIR}/librust_lib_origin_lens.a',
  }
end

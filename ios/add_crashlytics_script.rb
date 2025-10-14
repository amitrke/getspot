#!/usr/bin/env ruby
# Script to automatically add Crashlytics upload script to Xcode project
# Run this once: ruby ios/add_crashlytics_script.rb

require 'xcodeproj'

project_path = File.join(File.dirname(__FILE__), 'Runner.xcodeproj')
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'Runner' }

# Check if script already exists
existing_script = target.shell_script_build_phases.find do |phase|
  phase.name == 'Upload Crashlytics Symbols' ||
  phase.shell_script.include?('FirebaseCrashlytics/run') ||
  phase.shell_script.include?('upload-symbols')
end

if existing_script
  puts "✅ Crashlytics upload script already exists!"
  exit 0
end

# Find the position to insert (after Flutter build script, before other scripts)
flutter_build_phase_index = target.build_phases.find_index do |phase|
  phase.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase) &&
  phase.shell_script.include?('xcode_backend.sh') &&
  phase.shell_script.include?('build')
end

# Create new Run Script build phase
phase = target.new_shell_script_build_phase('Upload Crashlytics Symbols')
phase.shell_script = '"${PODS_ROOT}/FirebaseCrashlytics/run"'

# Add input files for dSYM upload
phase.input_paths = [
  '${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${TARGET_NAME}',
  '$(SRCROOT)/$(BUILT_PRODUCTS_DIR)/$(INFOPLIST_PATH)'
]

# Move the phase to the correct position if we found the Flutter build phase
if flutter_build_phase_index
  target.build_phases.delete(phase)
  target.build_phases.insert(flutter_build_phase_index + 1, phase)
  puts "✅ Added Crashlytics upload script after Flutter build phase"
else
  puts "✅ Added Crashlytics upload script at default position"
end

project.save

puts "✅ Done! Crashlytics symbols will now be uploaded on build."
puts "   Next steps:"
puts "   1. Commit the changes: git add ios/Runner.xcodeproj/project.pbxproj"
puts "   2. Push to trigger Xcode Cloud build"
puts "   3. Test crash reporting after the new build deploys"

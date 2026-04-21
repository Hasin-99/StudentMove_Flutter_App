require "xcodeproj"

project_path = File.expand_path("../ios/Runner.xcodeproj", __dir__)
project = Xcodeproj::Project.open(project_path)

flutter_group = project.groups.find { |g| g.name == "Flutter" }
raise "Flutter group not found" unless flutter_group

xcconfig_files = {
  "Debug-dev" => "Flutter/Debug-dev.xcconfig",
  "Release-dev" => "Flutter/Release-dev.xcconfig",
  "Profile-dev" => "Flutter/Profile-dev.xcconfig",
  "Debug-prod" => "Flutter/Debug-prod.xcconfig",
  "Release-prod" => "Flutter/Release-prod.xcconfig",
  "Profile-prod" => "Flutter/Profile-prod.xcconfig",
}

xcconfig_refs = {}
xcconfig_files.each do |config_name, rel_path|
  existing = project.files.find { |f| f.path == rel_path }
  ref = existing || flutter_group.new_file(rel_path.sub("Flutter/", ""))
  xcconfig_refs[config_name] = ref
end

def clone_configuration(project, config_list, base_name, new_name)
  existing = config_list.build_configurations.find { |cfg| cfg.name == new_name }
  return existing if existing

  base = config_list.build_configurations.find { |cfg| cfg.name == base_name }
  raise "Missing base config #{base_name}" unless base

  cloned = project.new(Xcodeproj::Project::Object::XCBuildConfiguration)
  cloned.name = new_name
  cloned.build_settings = base.build_settings.dup
  cloned.base_configuration_reference = base.base_configuration_reference
  config_list.build_configurations << cloned
  cloned
end

runner_target = project.targets.find { |t| t.name == "Runner" }
raise "Runner target not found" unless runner_target

project_config_list = project.root_object.build_configuration_list
runner_config_list = runner_target.build_configuration_list

{
  "Debug-dev" => "Debug",
  "Release-dev" => "Release",
  "Profile-dev" => "Profile",
  "Debug-prod" => "Debug",
  "Release-prod" => "Release",
  "Profile-prod" => "Profile",
}.each do |new_name, base_name|
  clone_configuration(project, project_config_list, base_name, new_name)
  cloned = clone_configuration(project, runner_config_list, base_name, new_name)
  cloned.base_configuration_reference = xcconfig_refs[new_name]

  if new_name.end_with?("-dev")
    cloned.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.example.studentmove.dev"
    cloned.build_settings["PRODUCT_NAME"] = "StudentMove Dev"
  end
end

project.save

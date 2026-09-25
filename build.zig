const std = @import("std");

const content_dir = "gui_test_content/";

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zglfw = b.dependency("zglfw", .{
        .target = target,
        .optimize = optimize,
    });

    const zstbi = b.dependency("zstbi", .{
        .target = target,
        .optimize = optimize,
    });

    //
    // Build Imgui with OpenGL backend
    //

    const zopengl = b.dependency("zopengl", .{
        .target = target,
    });

    const zgui_opengl = b.dependency("zgui", .{
        .target = target,
        .optimize = optimize,
        .backend = .glfw_opengl3,
        .with_te = true,
        .with_implot = true,
        .shared = false,
    });

    const exe = b.addExecutable(.{
        .name = "gui_test_opengl",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/gui_test_opengl3.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    exe.root_module.addImport("zopengl", zopengl.module("root"));
    exe.root_module.addImport("zgui", zgui_opengl.module("root"));
    exe.root_module.addImport("zglfw", zglfw.module("root"));
    exe.root_module.addImport("zstbi", zstbi.module("root"));

    exe.root_module.linkLibrary(zgui_opengl.artifact("imgui"));
    exe.root_module.linkLibrary(zglfw.artifact("glfw"));

    const exe_options = b.addOptions();
    exe.root_module.addOptions("build_options", exe_options);
    exe_options.addOption([]const u8, "content_dir", content_dir);

    const install_content_step = b.addInstallDirectory(.{
        .source_dir = b.path(content_dir),
        .install_dir = .{ .custom = "" },
        .install_subdir = "bin/" ++ content_dir,
    });

    exe.step.dependOn(&install_content_step.step);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run_opengl", "Run the app");
    run_step.dependOn(&run_cmd.step);

    //
    // Build Imgui with the WebGPU (Dawn) backend
    //

    const zgpu = b.dependency("zgpu", .{
        .target = target,
        .optimize = optimize,
    });

    const zgui_webgpu = b.dependency("zgui", .{
        .target = target,
        .optimize = optimize,
        .backend = .glfw_wgpu,
        .with_te = true,
        .with_implot = true,
        .shared = false,
    });

    const exe_webgpu = b.addExecutable(.{
        .name = "gui_test_webgpu",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/gui_test_webgpu.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    @import("zgpu").addLibraryPathsTo(exe_webgpu);

    exe_webgpu.root_module.addImport("zgpu", zgpu.module("root"));
    exe_webgpu.root_module.addImport("zgui", zgui_webgpu.module("root"));
    exe_webgpu.root_module.addImport("zglfw", zglfw.module("root"));
    exe_webgpu.root_module.addImport("zstbi", zstbi.module("root"));

    exe_webgpu.root_module.linkLibrary(zgpu.artifact("zdawn"));
    exe_webgpu.root_module.linkLibrary(zgui_webgpu.artifact("imgui"));
    exe_webgpu.root_module.linkLibrary(zglfw.artifact("glfw"));

    const exe_webgpu_options = b.addOptions();
    exe_webgpu.root_module.addOptions("build_options", exe_webgpu_options);
    exe_webgpu_options.addOption([]const u8, "content_dir", content_dir);

    b.installArtifact(exe_webgpu);

    const run_cmd_webgpu = b.addRunArtifact(exe_webgpu);
    run_cmd_webgpu.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd_webgpu.addArgs(args);
    }

    const run_step_webgpu = b.step("run_webgpu", "Run the app");
    run_step_webgpu.dependOn(&run_cmd_webgpu.step);
}

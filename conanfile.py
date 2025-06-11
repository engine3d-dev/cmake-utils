from conan import ConanFile
from conan.tools.files import copy
from conan.tools.layout import basic_layout
import os


required_conan_version = ">=2.0.6"


class engine3d_cmake_util_conan(ConanFile):
    name = "engine3d-cmake-utils"
    version = "4.0"
    license = "Apache-2.0"
    description = ("A collection of CMake for engine3d")
    topics = ("cmake")
    exports_sources = ("cmake/*", "LICENSE")
    no_copy_source = True
    options = {
        "add_build_outputs": [True, False],
        "optimize_debug_build": [True, False]
    }
    default_options = {
        "add_build_outputs": True,
        "optimize_debug_build": True
    }

    def package_id(self):
        self.info.clear()

    def layout(self):
        basic_layout(self)

    def package(self):
        copy(self, "LICENSE", dst=os.path.join(
            self.package_folder, "licenses"),  src=self.source_folder)
        copy(self, "cmake/*.cmake", src=self.source_folder,
             dst=self.package_folder)
        copy(self, "cmake/*.conf", src=self.source_folder,
             dst=self.package_folder)
        
    
    def package_info(self):
        # Add toolchain.cmake to user_toolchain configuration info to be used
        # by CMakeToolchain generator
        build_path = os.path.join(
            self.package_folder, "cmake/build.cmake")

        self.conf_info.append(
            "tools.cmake.cmaketoolchain:user_toolchain",
            build_path)




# # Overview

# Integrating job system to split tasks that can be executed in parallel. While removing the need of keeping frames in sync through sequences of phases within the main loop.

# ## Integrate Job System Capabilities

# These are the following features the job system, after integrated.

# - Delegate tasks to worker threads
# - Control flow of which worker threads and what tasks get submitted to worker thread.
# - Enable to do analysis when specific worker threads have been pending too long. (task stealing)
# - Should be able to split worker threads into groups that may execute very specific tasks that are required.

# ## Additional Core Changes

# These are changes along with this PR that will be part of the integration of the job system. Since this is going to be replacing the global and sync update entirely. For more information go to issues #92 for more information.

# We were experiencing issues of crashing when changing from `flecs/4.0.0`  to `flecs/4.0.4`, I updated system registry as mentioned below. These changes are going to be merged into dev along with the integration of the job system.

# - Removing global and sync update
# - Removing thread manager implementation
# - Updated system registry by also properly handle lifetimes.
#    - System registry updated to manage lifetimes of `world_scope`
#    - world_scope manages `scene_scope` properly
#    - Per `scene_scope` contains a `flecs::world` that manages entities corresponding to those scenes
# - Updated the vulkan renderer to work with the new API's added to system registry and world scope
# - Continuing applying snake case naming scheme in code base that weren't
# - Changed key, mouse, and joystick codes to follow snake-case, and enums as camel case.

# ## Future Consideration (post-integration)

# These are new features that wont be added into this implementation but are very important to consider.

# - Setup Dependency graph. To ensure that some worker thread groups do not do specific tasks. That may require other tasks to finish first before they could continue.
# - Setup an approach to setup requirements for specific work to be done, organized by groups of worker thread.
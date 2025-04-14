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



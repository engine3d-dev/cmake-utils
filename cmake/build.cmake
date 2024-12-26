# Generate compile commands for anyone using our libraries.
set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE INTERNAL "") # works (in creating the compile_commands.json file)

function(generate_compile_commands)
    # Copy to compile_commands.json for .clangd
    add_custom_target(
        copy-compile-commands ALL
        DEPENDS
            ${CMAKE_SOURCE_DIR}/compile_commands.json
    )

    # This will run the build doing -j which is building at full capacity.
    # TODO - Should probably have this be disabled by default and have this be a flag set through conan.
    # add_custom_target(my_parallel_build
    #                       COMMAND ${CMAKE_COMMAND} --build -j
    #                       WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    #                       COMMENT "My parallel build with 5 cores")


    add_custom_command(
        OUTPUT ${CMAKE_CURRENT_LIST_DIR}/compile_commands.json
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            ${CMAKE_BINARY_DIR}/compile_commands.json
        ${CMAKE_CURRENT_LIST_DIR}/compile_commands.json
        DEPENDS
        # Unlike "proper" targets like executables and libraries, 
        # custom command / target pairs will not set up source
        # file dependencies, so we need to list file explicitly here
        generate-compile-commands
        ${CMAKE_BINARY_DIR}/compile_commands.json
    )

    # Generate the compilation commands. Necessary so cmake knows where it came
    # from and if for some reason you delete it.
    add_custom_target(generate-compile-commands
        DEPENDS
            ${CMAKE_BINARY_DIR}/compile_commands.json
    )

    add_custom_command(
        OUTPUT ${CMAKE_BINARY_DIR}/compile_commands.json
        COMMAND ${CMAKE_COMMAND} -B${CMAKE_BINARY_DIR} -S${CMAKE_SOURCE_DIR}
    )
endfunction()

set(ENGINE_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/engine3d)

function(packages)
    set(options)
    set(one_value_args)
    set(multi_value_args SOURCES INCLUDES DIRECTORIES PACKAGES LINK_LIBRARIES)
    cmake_parse_arguments(DEMOS_ARGS
        "${options}"
        "${one_value_args}"
        "${multi_value_args}"
        ${ARGN}
    )

    #Set Compiler definitions
    set(is_msvc_cl $<CXX_COMPILER_ID:MSVC>)
    set(dev_definitions
        $<${is_msvc_cl}:JPH_FLOATING_POINT_EXCEPTIONS_ENABLED>
        JPH_PROFILE_ENABLED
        JPH_DEBUG_RENDERER
        JPH_OBJECT_STREAM
    )
    target_compile_definitions(${PROJECT_NAME} PRIVATE ${dev_definitions})
    
    # This is used because if we do not have this users systems may give them a linked error with oldnames.lib
    # Usage - used to suppress that lld-link error and use the defaulted linked .library
    if(MSVC)
    target_compile_options(${PROJECT_NAME} PUBLIC "/Z1" "/NOD")
    endif(MSVC)

    find_package(glfw3 REQUIRED)
    find_package(Vulkan REQUIRED)
    find_package(VulkanHeaders REQUIRED)
    if(UNIX AND NOT APPLE)
    endif(UNIX AND NOT APPLE)

    find_package(glm REQUIRED)
    find_package(fmt REQUIRED)
    find_package(spdlog REQUIRED)
    find_package(yaml-cpp REQUIRED)
    find_package(box2d REQUIRED)
    find_package(joltphysics REQUIRED)
    find_package(EnTT REQUIRED)
    find_package(imguidocking REQUIRED)

    target_include_directories(${PROJECT_NAME} PUBLIC ${JoltPhysics_SOURCE_DIR}/..)

    target_link_libraries(
        ${PROJECT_NAME}
        PUBLIC
        glfw
        ${OPENGL_LIBRARIES}
        Vulkan::Vulkan
        vulkan-headers::vulkan-headers
        imguidocking::imguidocking
        glm::glm
        fmt::fmt
        spdlog::spdlog
        yaml-cpp::yaml-cpp
        box2d::box2d
        Jolt::Jolt
        EnTT::EnTT
    )
endfunction()



function(build_demos)
    set(options)
    set(one_value_args)
    set(multi_value_args SOURCES INCLUDES DIRECTORIES PACKAGES LINK_PACKAGES)
    cmake_parse_arguments(DEMOS_ARGS
        "${options}"
        "${one_value_args}"
        "${multi_value_args}"
        ${ARGN}
    )
    set(CMAKE_CXX_STANDARD 23)

    add_executable(${PROJECT_NAME} ${DEMOS_ARGS_SOURCES})
    
    target_include_directories(${PROJECT_NAME} PUBLIC ${ENGINE_INCLUDE_DIR})
    # target_include_directories(${PROJECT_NAME} PRIVATE ../${ENGINE_INCLUDE_DIR}/engine3d/core ${DEMOS_ARGS_INCLUDES})

    target_link_libraries(${PROJECT_NAME} PUBLIC engine3d)
    packages(
        PACKAGES ${DEMOS_ARGS_PACKAGES}
        LINK_LIBRARIES ${DEMOS_ARGS_LINK_PACKAGES}
    )
    
endfunction()


# Takes in add_subdirectory instead of sources
function(build_library)
    message("[ENGINE3D] Building engine3d core library")
    # Parse CMake function arguments
    set(options)
    set(one_value_args)
    set(multi_value_args SOURCES INCLUDES DIRECTORIES PACKAGES LINK_PACKAGES NO_PACKAGES)
    cmake_parse_arguments(DEMOS_ARGS
        "${options}"
        "${one_value_args}"
        "${multi_value_args}"
        ${ARGN}
    )

    set(CMAKE_CXX_STANDARD 23)

    # So if we were to add  Editor this would do add_subdirectory(Editor)
    # Usage: build_library(DIRECTORIES Editor TestApp)
    foreach(SUBDIRS ${DEMOS_ARGS_DIRECTORIES})
        message("[ENGINE3D] Added \"${SUBDIRS}\"")
        add_subdirectory(${SUBDIRS})
    endforeach()

    generate_compile_commands()

    target_include_directories(${PROJECT_NAME} PUBLIC ${ENGINE_INCLUDE_DIR})
    target_include_directories(${PROJECT_NAME} PRIVATE ${ENGINE_INCLUDE_DIR}/core)

    packages(
        PACKAGES ${DEMOS_ARGS_PACKAGES} 
        LINK_LIBRARIES ${DEMOS_ARGS_LINK_PACKAGES}
    )

endfunction()

function(build_application)
    # Parse CMake function arguments
    set(options)
    set(one_value_args)
    set(multi_value_args SOURCES INCLUDES DIRECTORIES PACKAGES LINK_PACKAGES NO_PACKAGES)
    cmake_parse_arguments(DEMOS_ARGS
        "${options}"
        "${one_value_args}"
        "${multi_value_args}"
        ${ARGN}
    )

    set(CMAKE_CXX_STANDARD 23)

    # Linking specified packages from the user
    add_executable(${PROJECT_NAME} ${DEMOS_ARGS_SOURCES})

    generate_compile_commands()

    foreach(PACKAGE ${DEMOS_ARGS_PACKAGES})
        message("[ENGINE3D] Added packages ${PACKAGE}")
        find_package(${PACKAGE} REQUIRED)
    endforeach()

    target_link_libraries(${PROJECT_NAME} PUBLIC ${DEMOS_ARGS_LINK_PACKAGES})
    
endfunction()
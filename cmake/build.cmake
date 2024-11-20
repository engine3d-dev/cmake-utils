# Generate compile commands for anyone using our libraries.
set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE INTERNAL "") # works (in creating the compile_commands.json file)

function(generate_compile_commands)
    # Copy to compile_commands.json for .clangd
    add_custom_target(
        copy-compile-commands ALL
        DEPENDS
            ${CMAKE_SOURCE_DIR}/compile_commands.json
    )

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

# Assumes that our target_include_directories is engine3d.
# This is only used for the engine3d project, specifically.
# We also want to make sure that any engine3d related organization packages are ones we can add.

# TODO: Probably want to modify this in the future.
function(build_demos)
    # Parse CMake function arguments
    set(options)
    set(one_value_args)
    set(multi_value_args SOURCES INCLUDES DIRECTORIES PACKAGES LINK_LIBRARIES)
    cmake_parse_arguments(DEMOS_ARGS
        "${options}"
        "${one_value_args}"
        "${multi_value_args}"
        ${ARGN}
    )

    add_executable(${DEMOS_ARGS_PROJECT_NAME} ${DEMOS_ARGS_SOURCES})

endfunction()


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

    # #Set Compiler definitions
    set(is_msvc_cl $<CXX_COMPILER_ID:MSVC>)
    set(dev_definitions
        $<${is_msvc_cl}:JPH_FLOATING_POINT_EXCEPTIONS_ENABLED>
        JPH_PROFILE_ENABLED
        JPH_DEBUG_RENDERER
        JPH_OBJECT_STREAM
    )

    target_compile_definitions(${PROJECT_NAME} PRIVATE ${dev_definitions})

    foreach(PACKAGE ${DEMOS_ARGS_PACKAGES})
        find_package(${PACKAGE} REQUIRED)
    endforeach()

    find_package(OpenGL REQUIRED)
    find_package(Vulkan REQUIRED)
    find_package(VulkanHeaders REQUIRED)
    if(LINUX)
        find_package(VulkanLoader REQUIRED)
    endif()

    find_package(glm REQUIRED)
    find_package(fmt REQUIRED)
    find_package(spdlog REQUIRED)
    find_package(yaml-cpp REQUIRED)
    find_package(imguidocking REQUIRED)
    find_package(box2d REQUIRED)
    find_package(joltphysics REQUIRED)
    find_package(EnTT REQUIRED)


    if(WIN32)
    target_link_libraries(
        ${PROJECT_NAME}
        PRIVATE
        glfw
        ${OPENGL_LIBRARIES}
        Vulkan::Vulkan
        vulkan-headers::vulkan-headers
        glm::glm
        fmt::fmt
        spdlog::spdlog
        yaml-cpp::yaml-cpp
        imguidocking::imguidocking
        box2d::box2d
        Jolt::Jolt
        EnTT::EnTT
        ${DEMOS_ARGS_LINK_LIBRARIES}
    )
    endif(WIN32)

    if(LINUX)
    target_link_libraries(
        ${PROJECT_NAME}
        PRIVATE
        glfw
        ${OPENGL_LIBRARIES}
        vulkan-headers::vulkan-headers
        Vulkan::Loader
        glm::glm
        fmt::fmt
        spdlog::spdlog
        yaml-cpp::yaml-cpp
        imguidocking::imguidocking
        box2d::box2d
        Jolt::Jolt
        EnTT::EnTT
        ${DEMOS_ARGS_LINK_LIBRARIES}
    )
    endif(LINUX)

    if(APPLE)
    target_link_libraries(
        ${PROJECT_NAME}
        PRIVATE
        glfw
        ${OPENGL_LIBRARIES}
        vulkan-headers::vulkan-headers
        Vulkan::Vulkan
        glm::glm
        fmt::fmt
        spdlog::spdlog
        yaml-cpp::yaml-cpp
        imguidocking::imguidocking
        box2d::box2d
        Jolt::Jolt
        EnTT::EnTT
        ${DEMOS_ARGS_LINK_LIBRARIES}
    )
    endif(APPLE)
endfunction()



function(build_subdir_demos)
    set(options)
    set(one_value_args)
    set(multi_value_args SOURCES INCLUDES DIRECTORIES PACKAGES LINK_LIBRARIES)
    cmake_parse_arguments(DEMOS_ARGS
        "${options}"
        "${one_value_args}"
        "${multi_value_args}"
        ${ARGN}
    )
    set(CMAKE_CXX_STANDARD 23)
    
    add_executable(${PROJECT_NAME} ${DEMOS_ARGS_SOURCES})
    
    target_include_directories(${PROJECT_NAME} PUBLIC ../${ENGINE_INCLUDE_DIR} ${JoltPhysics_SOURCE_DIR} ${EnTT_INCLUDE_DIR} ${GLM_INCLUDE_DIR})
    target_include_directories(${PROJECT_NAME} PRIVATE ../${ENGINE_INCLUDE_DIR}/Core)

    packages(
        PACKAGES ${DEMOS_ARGS_PACKAGES}
        LINK_LIBRARIES ${DEMOS_ARGS_LINK_LIBRARIES}
    )
    
endfunction()




function(build_subdirs)
    # Parse CMake function arguments
    set(options)
    set(one_value_args)
    set(multi_value_args SOURCES INCLUDES DIRECTORIES PACKAGES LINK_LIBRARIES)
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
        add_subdirectory(${SUBDIRS})
    endforeach()

    target_include_directories(${PROJECT_NAME} PUBLIC ${ENGINE_INCLUDE_DIR} ${JoltPhysics_SOURCE_DIR} ${EnTT_INCLUDE_DIR} ${GLM_INCLUDE_DIR})
    target_include_directories(${PROJECT_NAME} PRIVATE ${ENGINE_INCLUDE_DIR}/Core)


    packages(
        PACKAGES ${DEMOS_ARGS_PACKAGES} 
        LINK_LIBRARIES ${DEMOS_ARGS_LINK_LIBRARIES}
    )

endfunction()
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

# Define the function that accepts a variable number of arguments
# used for building applications
function(build_demos)
  # Parse CMake function arguments
  set(options)
  set(one_value_args)
  set(multi_value_args SOURCES INCLUDES PACKAGES LINK_LIBRARIES)
  cmake_parse_arguments(DEMOS_ARGS
    "${options}"
    "${one_value_args}"
    "${multi_value_args}"
    ${ARGN})

    set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE INTERNAL "") # works (in creating the compile_commands.json file)

    add_executable(${PROJECT_NAME} ${DEMOS_ARGS_SOURCES})

    # This is used because if we do not have this users systems may give them a linked error with oldnames.lib
    # Usage - used to suppress that lld-link error and use the defaulted linked .library
    if(MSVC)
        target_compile_options(${PROJECT_NAME} PUBLIC "/Z1" "/NOD")
    endif(MSVC)
    find_package(engine3d REQUIRED)

    find_package(OpenGL REQUIRED)
    find_package(glfw3 REQUIRED)

    find_package(Vulkan REQUIRED)
    find_package(VulkanHeaders REQUIRED)

    if(LINUX)
    find_package(VulkanLoader REQUIRED)
    endif(LINUX)

    target_include_directories(${PROJECT_NAME} PUBLIC ${ENGINE_INCLUDE_DIR})

    find_package(glm REQUIRED)
    find_package(fmt REQUIRED)
    find_package(spdlog REQUIRED)
    find_package(yaml-cpp REQUIRED)
    find_package(imguidocking REQUIRED)
    find_package(box2d REQUIRED)
    find_package(joltphysics REQUIRED)
    find_package(EnTT REQUIRED)

    # Set Compiler definitions required for JoltPhysics
    if(MSVC)
        set(is_msvc_cl $<CXX_COMPILER_ID:MSVC>)
        set(global_definitions
            $<${is_msvc_cl}:JPH_FLOATING_POINT_EXCEPTIONS_ENABLED>
            JPH_PROFILE_ENABLED
            JPH_DEBUG_RENDERER
            JPH_OBJECT_STREAM
        )
        target_include_directories(${PROJECT_NAME} PRIVATE ${global_definitions})
    endif(MSVC)

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
        engine3d::engine3d
    )

    if(LINUX)
    target_link_libraries(
        ${PROJECT_NAME}
        PRIVATE
        glfw
        ${OPENGL_LIBRARIES}
        Vulkan::Loader
        glm::glm
        fmt::fmt
        spdlog::spdlog
        yaml-cpp::yaml-cpp
        imguidocking::imguidocking
        box2d::box2d
        Jolt::Jolt
        EnTT::EnTT
        engine3d::engine3d
    )
    endif(LINUX)
endfunction()


function(build_library)
  # Parse CMake function arguments
  set(options)
  set(one_value_args)
  set(multi_value_args SOURCES INCLUDES PACKAGES LINK_LIBRARIES)
  cmake_parse_arguments(DEMOS_ARGS
    "${options}"
    "${one_value_args}"
    "${multi_value_args}"
    ${ARGN})

    set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE INTERNAL "") # works (in creating the compile_commands.json file)

    add_library(${PROJECT_NAME} ${DEMOS_ARGS_SOURCES})

    # This is used because if we do not have this users systems may give them a linked error with oldnames.lib
    # Usage - used to suppress that lld-link error and use the defaulted linked .library
    if(MSVC)
        target_compile_options(${PROJECT_NAME} PUBLIC "/Z1" "/NOD")
    endif(MSVC)
    
    find_package(OpenGL REQUIRED)
    find_package(glfw3 REQUIRED)

    find_package(Vulkan REQUIRED)
    find_package(VulkanHeaders REQUIRED)

    if(LINUX)
    find_package(VulkanLoader REQUIRED)
    endif(LINUX)

    target_include_directories(${PROJECT_NAME} PRIVATE ${ENGINE_INCLUDE_DIR}/Core)
    target_include_directories(${PROJECT_NAME} PUBLIC ${JoltPhysics_SOURCE_DIR} ${GLM_INCLUDE_DIR} ${ENGINE_INCLUDE_DIR})

    find_package(glm REQUIRED)
    find_package(fmt REQUIRED)
    find_package(spdlog REQUIRED)
    find_package(yaml-cpp REQUIRED)
    find_package(imguidocking REQUIRED)
    find_package(box2d REQUIRED)
    find_package(joltphysics REQUIRED)
    find_package(EnTT REQUIRED)


    if(LINUX)
    target_link_libraries(
        ${PROJECT_NAME}
        PRIVATE
        glfw
        ${OPENGL_LIBRARIES}
        Vulkan::Loader
        vulkan-headers::vulkan-headers
        glm::glm
        fmt::fmt
        spdlog::spdlog
        yaml-cpp::yaml-cpp
        imguidocking::imguidocking
        box2d::box2d
        Jolt::Jolt
        EnTT::EnTT
    )
    else()
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
        EnTT::EnTT
    )
    endif()

    install(TARGETS ${PROJECT_NAME})
endfunction()


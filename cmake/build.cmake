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

set(ENGINE_INCLUDE_DIR ${CMAKE_CURRENT_LIST_DIR}/atlas)

function(packages)
    set(options)
    set(one_value_args)
    set(multi_value_args SOURCES INCLUDES DIRECTORIES PACKAGES LINK_PACKAGES)
    cmake_parse_arguments(DEMOS_ARGS
        "${options}"
        "${one_value_args}"
        "${multi_value_args}"
        ${ARGN}
    )
    
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
    find_package(box2d REQUIRED)
    find_package(imguidocking REQUIRED)

    find_package(Jolt REQUIRED)
    find_package(yaml-cpp REQUIRED)
    find_package(stb REQUIRED)
    find_package(flecs REQUIRED)
    find_package(nfd REQUIRED)

    foreach(PACKAGE_NAME ${DEMOS_ARGS_PACKAGES})
        message(${Blue} "-- [ENGINE] Added Package ${PACKAGE_NAME}")
        find_package(${PACKAGE_NAME} REQUIRED)
    endforeach()

    set(VULKAN_LINK_LIBS "")

    if(WIN32)
        list(${VULKAN_LINK_LIBS} APPEND Vulkan::Vulkan)
    endif(WIN32)

    if(UNIX AND NOT APPLE)
        list(${VULKAN_LINK_LIBS} APPEND Vulkan::Loader)
    endif(UNIX AND NOT APPLE)

    target_link_libraries(
        ${PROJECT_NAME}
        PUBLIC
        glfw
        ${OPENGL_LIBRARIES}
        # Vulkan::Vulkan
        ${VULKAN_LINK_LIBS}
        vulkan-headers::vulkan-headers
        imguidocking::imguidocking
        glm::glm
        fmt::fmt
        spdlog::spdlog

        Jolt::Jolt
        yaml-cpp
        stb::stb

        flecs::flecs_static
        nfd::nfd
        ${DEMOS_ARGS_LINK_PACKAGES}
    )
endfunction()

function(build_unit_test)
    set(options)
    set(one_value_args)
    set(multi_value_args SOURCES TEST_SOURCES INCLUDES DIRECTORIES PACKAGES LINK_PACKAGES)
    cmake_parse_arguments(DEMOS_ARGS
        "${options}"
        "${one_value_args}"
        "${multi_value_args}"
        ${ARGN}
    )

    # This goes through all of our sources and checks if they are valid sources 
    foreach(EACH_UNIT_TEST_SOURCE ${DEMOS_ARGS_TEST_SOURCES})
        message("-- [ENGINE] Testing '${EACH_UNIT_TEST_SOURCE}'")
    endforeach()

    find_package(ut REQUIRED CONFIG)

    add_executable(
        unit_test
        ${DEMOS_ARGS_TEST_SOURCES}
    )

    target_link_libraries(unit_test PRIVATE boost-ext-ut::ut ${DEMOS_ARGS_LINK_PACKAGES})

    target_compile_options(unit_test PRIVATE
        --coverage
        -fprofile-arcs
        -ftest-coverage
        -Werror
        -Wall
        -Wextra
        -Wshadow
        -Wnon-virtual-dtor
        -Wno-gnu-statement-expression
        -pedantic
        -g
    )

    target_link_options(unit_test PRIVATE
        --coverage
        -fprofile-arcs
        -ftest-coverage
    )

    target_include_directories(unit_test PRIVATE ${CMAKE_CURRENT_LIST_DIR}/tests ${CMAKE_CURRENT_LIST_DIR}/engine3d/core)
    
    # Specifying to cmake to run unit_test before engine3d's Editor runs
    # [unit_test required -> [then do] -> Editor]
    # add_dependencies(unit_test editor)
    add_custom_target(run_tests ALL DEPENDS unit_test COMMAND unit_test)

endfunction()

# Should be used by client application
function(build_application)
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

    # target_compile_options(${PROJECT_NAME} PRIVATE
    #     -g
    #     --coverage
    #     -fprofile-arcs
    #     -ftest-coverage
    #     -Werror
    #     -Wall
    #     -Wextra
    #     -Wshadow
    #     -Wnon-virtual-dtor
    #     -Wno-gnu-statement-expression
    #     -pedantic
    # )

    # target_link_options(${PROJECT_NAME} PRIVATE
    #     --coverage
    #     -fprofile-arcs
    #     -ftest-coverage
    # )

    foreach(PACKAGE ${DEMOS_ARGS_PACKAGES})
        message("-- [${PROJECT_NAME}] Added Packages ${PACKAGE}")
        find_package(${PACKAGE} REQUIRED)
    endforeach()

    target_link_libraries(${PROJECT_NAME} PUBLIC ${DEMOS_ARGS_LINK_PACKAGES})
    
endfunction()


# Used by the core engine itself. Users SHOULD NOT be using this function
function(build_core_library)
    message("-- [ENGINE] Building core engine library")
    # Parse CMake function parameters
    set(options)
    set(one_value_args)
    set(multi_value_args SOURCES UNIT_TEST_SOURCES INCLUDES DIRECTORIES ENABLE_TESTS PACKAGES LINK_PACKAGES NO_PACKAGES)
    cmake_parse_arguments(DEMOS_ARGS
        "${options}"
        "${one_value_args}"
        "${multi_value_args}"
        ${ARGN}
    )
    option(${DEMOS_ARGS_ENABLE_TESTS} "[ENGINE] Enabling unit testing" OFF)

    set(CMAKE_CXX_STANDARD 23)

    # Setting up unit tests part of the build process
    # set(ENABLING_TESTS ${DEMOS_ARGS_ENABLE_TESTS})
    if(${DEMOS_ARGS_ENABLE_TESTS})
        message("-- [ENGINE] Enabling Unit Tests")
        build_unit_test(
            TEST_SOURCES ${DEMOS_ARGS_UNIT_TEST_SOURCES}
            LINK_PACKAGES atlas
        )
    endif()
    
    # So if we were to add  Editor this would do add_subdirectory(Editor)
    # Usage: build_library(DIRECTORIES Editor TestApp)
    foreach(SUBDIRS ${DEMOS_ARGS_DIRECTORIES})
        message("-- [ENGINE] Added \"${SUBDIRS}\"")
        add_subdirectory(${SUBDIRS})
    endforeach()
    
    if(UNIX AND NOT APPLE)
    message("ON LINUX SETTING COMPILE FLAGS")
    target_compile_options(
        ${PROJECT_NAME}
        PUBLIC
        -g -Wall -Wextra -Wno-missing-field-initializers -Wshadow
    )
    else()
    target_compile_options(
        ${PROJECT_NAME}
        PUBLIC
        -g -Werror -Wall -Wextra -Wno-missing-field-initializers -Wshadow
    )
    endif(UNIX AND NOT APPLE)

    # target_compile_options(${PROJECT_NAME} PRIVATE)

    generate_compile_commands()

    target_include_directories(${PROJECT_NAME} PUBLIC ${ENGINE_INCLUDE_DIR})
    target_include_directories(${PROJECT_NAME} PRIVATE ${ENGINE_INCLUDE_DIR}/core)

    packages(
        PACKAGES ${DEMOS_ARGS_PACKAGES} 
        LINK_PACKAGES ${DEMOS_ARGS_LINK_PACKAGES}
    )

endfunction()



function(build_library)
    # Parse CMake function parameters
    set(options)
    set(one_value_args)
    set(multi_value_args SOURCES PUBLIC_INCLUDES DIRECTORIES ENABLE_TESTS UNIT_TEST_SOURCES PACKAGES LINK_PACKAGES NO_PACKAGES)
    
    cmake_parse_arguments(DEMOS_ARGS
        "${options}"
        "${one_value_args}"
        "${multi_value_args}"
        ${ARGN}
    )

    set(CMAKE_CXX_STANDARD 23)

    # Setting up unit tests part of the build process
    # set(ENABLING_TESTS ${DEMOS_ARGS_ENABLE_TESTS})
    if(${DEMOS_ARGS_ENABLE_TESTS})
        message("-- [ENGINE] Enabling Unit Tests")
        build_unit_test(
            TEST_SOURCES ${DEMOS_ARGS_UNIT_TEST_SOURCES}
            LINK_PACKAGES ${LINK_PACKAGES}
        )
    endif()

    # So if we were to add  Editor this would do add_subdirectory(Editor)
    # Usage: build_library(DIRECTORIES Editor TestApp)
    foreach(SUBDIRS ${DEMOS_ARGS_DIRECTORIES})
        message("-- [${PROJECT_NAME}] Added \"${SUBDIRS}\"")
        add_subdirectory(${SUBDIRS})
    endforeach()


    target_include_directories(${PROJECT_NAME} PUBLIC ${DEMOS_ARGS_PUBLIC_INCLUDES})
    target_include_directories(${PROJECT_NAME} PRIVATE ${DEMOS_ARGS_PRIVATE_INCLUDES})

    foreach(PACKAGE_NAME ${DEMOS_ARGS_PACKAGES} )
        message(${Blue} "-- [${PROJECT_NAME}] Added Package ${PACKAGE_NAME}")
        find_package(${PACKAGE_NAME} REQUIRED)
    endforeach()

    target_link_libraries(
        ${PROJECT_NAME}
        PUBLIC
        ${DEMOS_ARGS_LINK_PACKAGES}
    )
endfunction()
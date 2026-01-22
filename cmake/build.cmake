# Generate compile commands for anyone using our libraries.
set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE INTERNAL "") # works (in creating the compile_commands.json file)


string(ASCII 27 Esc)
set(ColourReset "${Esc}[m")
set(ColourBold  "${Esc}[1m")
set(Red         "${Esc}[31m")
set(Green       "${Esc}[32m")
set(Yellow      "${Esc}[33m")
set(Blue        "${Esc}[34m")
set(Magenta     "${Esc}[35m")
set(Cyan        "${Esc}[36m")
set(White       "${Esc}[37m")
set(BoldRed     "${Esc}[1;31m")
set(BoldGreen   "${Esc}[1;32m")
set(BoldYellow  "${Esc}[1;33m")
set(BoldBlue    "${Esc}[1;34m")
set(BoldMagenta "${Esc}[1;35m")
set(BoldCyan    "${Esc}[1;36m")
set(BoldWhite   "${Esc}[1;37m")
set(ColorReset  "${Esc}[m")
set(ColorGreen  "${Esc}[32m")
set(ColorBlue   "${Esc}[34m") # This is the code for Blue

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

function(set_packages)
    set(options)
    set(one_value_args)
    set(multi_value_args SOURCES INCLUDES DIRECTORIES PACKAGES LINK_PACKAGES)
    cmake_parse_arguments(DEMOS_ARGS
        "${options}"
        "${one_value_args}"
        "${multi_value_args}"
        ${ARGN}
    )

    foreach(PACKAGE_NAME ${DEMOS_ARGS_PACKAGES})
        find_package(${PACKAGE_NAME} REQUIRED)
    endforeach()


    target_link_libraries(
        ${PROJECT_NAME}
        PUBLIC
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
        message(STATUS "${BoldBlue}[${PROJECT_NAME}]:${ColorReset} Testing '${EACH_UNIT_TEST_SOURCE}'")
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

    foreach(PACKAGE ${DEMOS_ARGS_PACKAGES})
        find_package(${PACKAGE} REQUIRED)
    endforeach()

    target_include_directories(${PROJECT_NAME} PUBLIC ${DEMOS_ARGS_INCLUDES})
    target_link_libraries(${PROJECT_NAME} PUBLIC ${DEMOS_ARGS_LINK_PACKAGES})
    
endfunction()

function(static_library)
    # Parse CMake function parameters
    set(options)
    set(one_value_args)
    set(multi_value_args SOURCES INCLUDE_DIRS DIRECTORIES ENABLE_TESTS UNIT_TEST_SOURCES PACKAGES LINK_PACKAGES)
    
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
        message(STATUS "${BoldBlue}[${PROJECT_NAME}]:${ColorReset} Testing Enabled")
        build_unit_test(
            TEST_SOURCES
            ${DEMOS_ARGS_UNIT_TEST_SOURCES}

            PACKAGES
            ${DEMOS_ARGS_PACKAGES}

            LINK_PACKAGES
            ${DEMOS_ARGS_LINK_PACKAGES}
        )
    endif()

    add_library(${PROJECT_NAME} STATIC)

    target_include_directories(${PROJECT_NAME} PUBLIC ${DEMOS_ARGS_PUBLIC_INCLUDE_DIRS})
    target_include_directories(${PROJECT_NAME} PRIVATE ${DEMOS_ARGS_PRIVATE_INCLUDE_DIRS})
    # This is used because if we do not have this users systems may give them a linked error with oldnames.lib
    # Usage - used to suppress that lld-link error and use the defaulted linked .library
    if(MSVC)
    target_compile_options(${PROJECT_NAME} PUBLIC "/Z1" "/NOD")
    endif(MSVC)

    set_packages(
        PACKAGES ${DEMOS_ARGS_PACKAGES}
        LINK_PACKAGES ${DEMOS_ARGS_LINK_PACKAGES}
    )
endfunction()
cmake_minimum_required(VERSION 3.19)

project(tree-sitter-native
        VERSION "0.1.0"
        DESCRIPTION "Native tree-sitter libraries for .NET bindings"
        HOMEPAGE_URL ""
        LANGUAGES C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Output directory for built libraries (mirrors native/out/{platform}/ structure)
set(TREE_SITTER_OUTPUT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/out/${CMAKE_SYSTEM_NAME}-${CMAKE_SYSTEM_PROCESSOR}"
    CACHE PATH "Directory to copy built .so/.dylib/.dll files into")

# -------------------------------------------------------
# Helper: add a grammar subdirectory and redirect its output
# -------------------------------------------------------
function(add_grammar dir_name)
    set(grammar_dir "${CMAKE_CURRENT_SOURCE_DIR}/${dir_name}")
    if(EXISTS "${grammar_dir}/CMakeLists.txt")
        add_subdirectory(${dir_name} ${CMAKE_CURRENT_BINARY_DIR}/${dir_name}_build)
    else()
        message(WARNING "Skipping ${dir_name}: no CMakeLists.txt found in ${grammar_dir}")
    endif()
endfunction()

# -------------------------------------------------------
# tree-sitter core
# -------------------------------------------------------
add_grammar(tree-sitter)
if(TARGET tree-sitter)
    set_target_properties(tree-sitter PROPERTIES
        OUTPUT_NAME "tree-sitter"
        LIBRARY_OUTPUT_DIRECTORY "${TREE_SITTER_OUTPUT_DIR}"
        ARCHIVE_OUTPUT_DIRECTORY "${TREE_SITTER_OUTPUT_DIR}"
    )
endif()

# -------------------------------------------------------
# Grammars (names must match the target names in each grammar's CMakeLists.txt)
# PHP and TypeScript have nested subdirectories that create additional targets:
#   PHP -> tree-sitter-php, tree-sitter-php_only
#   TypeScript -> tree-sitter-typescript, tree-sitter-tsx
# -------------------------------------------------------
add_grammar(tree-sitter-python)
add_grammar(tree-sitter-javascript)
add_grammar(tree-sitter-cpp)
add_grammar(tree-sitter-c-sharp)
add_grammar(tree-sitter-java)
add_grammar(tree-sitter-php)
add_grammar(tree-sitter-go)
add_grammar(tree-sitter-ruby)
add_grammar(tree-sitter-typescript)
# tree-sitter-bsl submodule may not be initialized (requires SSH access); skip if no source
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/tree-sitter-bsl/src/grammar.json")
    add_grammar(tree-sitter-bsl)
endif()

# Redirect output of all shared library targets to the output directory
set(ALL_TARGETS tree-sitter tree-sitter-python tree-sitter-javascript tree-sitter-cpp
                tree-sitter-c-sharp tree-sitter-java tree-sitter-php tree-sitter-go
                tree-sitter-ruby tree-sitter-typescript
                tree-sitter-php_only tree-sitter-tsx)

foreach(t ${ALL_TARGETS})
    if(TARGET ${t})
        get_target_property(lib_type ${t} TYPE)
        if(lib_type STREQUAL "SHARED_LIBRARY")
            set_target_properties(${t} PROPERTIES
                LIBRARY_OUTPUT_DIRECTORY "${TREE_SITTER_OUTPUT_DIR}"
                ARCHIVE_OUTPUT_DIRECTORY "${TREE_SITTER_OUTPUT_DIR}"
            )
        endif()
    endif()
endforeach()

# -------------------------------------------------------
# Cross-platform library naming (prefix "lib" on Unix targets, no prefix on Windows)
# Uses CMAKE_SYSTEM_NAME (the target OS) rather than UNIX (the host OS)
# so cross-compilation from macOS to Windows produces .dll without "lib" prefix.
# -------------------------------------------------------
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    foreach(t ${ALL_TARGETS})
        if(TARGET ${t})
            set_target_properties(${t} PROPERTIES PREFIX "")
        endif()
    endforeach()
else()
    foreach(t ${ALL_TARGETS})
        if(TARGET ${t})
            set_target_properties(${t} PROPERTIES PREFIX "lib")
        endif()
    endforeach()
endif()

# -------------------------------------------------------
# Convenience target: build-all
# -------------------------------------------------------
add_custom_target(build-all
    DEPENDS tree-sitter
            tree-sitter-python
            tree-sitter-javascript
            tree-sitter-cpp
            tree-sitter-c-sharp
            tree-sitter-java
            tree-sitter-php
            tree-sitter-go
            tree-sitter-ruby
            tree-sitter-typescript
            tree-sitter-php_only
            tree-sitter-tsx
            $<$<TARGET_EXISTS:tree-sitter-bsl>:tree-sitter-bsl>
    COMMENT "Building all native tree-sitter libraries"
)

# -------------------------------------------------------
# Convenience target: clean output directory
# -------------------------------------------------------
add_custom_target(clean-output
    COMMAND ${CMAKE_COMMAND} -E remove_directory "${TREE_SITTER_OUTPUT_DIR}"
    COMMENT "Removing output directory ${TREE_SITTER_OUTPUT_DIR}"
    VERBATIM
)

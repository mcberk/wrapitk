###############################################################################
# configure tcl
find_package(TCL REQUIRED)
# Hide useless settings provided by FindTCL.
foreach(entry TCL_LIBRARY_DEBUG
              TK_LIBRARY_DEBUG
              TCL_STUB_LIBRARY
              TCL_STUB_LIBRARY_DEBUG
              TK_STUB_LIBRARY
              TK_STUB_LIBRARY_DEBUG
              TK_WISH)
  set(${entry} "${${entry}}" CACHE INTERNAL "This value is not used by ITK.")
endforeach(entry)

include_directories(${TCL_INCLUDE_PATH} ${TK_INCLUDE_PATH})


###############################################################################
# store the current dir, so it can be reused later
set(WRAP_ITK_TCL_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}" CACHE INTERNAL "tcl source dir")
set(WRAP_ITK_TCL_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}" CACHE INTERNAL "tcl binary dir")


###############################################################################
# create the tcl directory in the classindex dir
file(MAKE_DIRECTORY ${WRAPPER_MASTER_INDEX_OUTPUT_DIR}/tcl)


###############################################################################
# Configure pkgIndex.tcl for the build tree.
if(CMAKE_CONFIGURATION_TYPES)
  foreach(config ${CMAKE_CONFIGURATION_TYPES})
    set(WRAP_ITK_TCL_PACKAGE_DIR "${LIBRARY_OUTPUT_PATH}/${config}")
    configure_file("${CMAKE_CURRENT_SOURCE_DIR}/pkgIndex.tcl.in"
                   "${CMAKE_CURRENT_BINARY_DIR}/${config}/pkgIndex.tcl"
                   @ONLY IMMEDIATE)
  endforeach(config)
else(CMAKE_CONFIGURATION_TYPES)
  set(WRAP_ITK_TCL_PACKAGE_DIR "${LIBRARY_OUTPUT_PATH}")
  configure_file("${CMAKE_CURRENT_SOURCE_DIR}/pkgIndex.tcl.in"
                 "${CMAKE_CURRENT_BINARY_DIR}/pkgIndex.tcl"
                 @ONLY IMMEDIATE)
endif(CMAKE_CONFIGURATION_TYPES)

# configure pkgIndex.tcl for the installed tree
set(WRAP_ITK_TCL_PACKAGE_DIR "${CMAKE_INSTALL_PREFIX}/${WRAP_ITK_INSTALL_PREFIX}/lib")
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/pkgIndex.tcl.in"
               "${CMAKE_CURRENT_BINARY_DIR}/InstallOnly/itkwish_wont_find_me_here/pkgIndex.tcl"
               @ONLY IMMEDIATE)
WRAP_ITK_INSTALL(/Tcl "${CMAKE_CURRENT_BINARY_DIR}/InstallOnly/itkwish_wont_find_me_here/pkgIndex.tcl")


###############################################################################
# Configure itkwish
set(WRAP_ITK_TCL_EXE_DIR_BUILD "${ITK_EXECUTABLE_PATH}")
set(WRAP_ITK_TCL_EXE_NAME_ROOT "itkwish")

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/itkTclConfigure.h.in
               ${CMAKE_CURRENT_BINARY_DIR}/itkTclConfigure.h
               @ONLY IMMEDIATE)


# Configure itkTclModules.h with the names of the initializer functions for the
# selected modules. For some pathological reason, the names are in the format:
# Modulename_Init
# where the first character is uppercase and the rest of the module name is
# lower case. Which will entail some amount of pain to create in CMake.
set(module_init_names )
foreach(module ${WRAP_ITK_LIBRARIES})
  string(REGEX REPLACE "^(.)(.+)$" "\\1" first "${module}")
  string(REGEX REPLACE "^(.)(.+)$" "\\2" rest "${module}")
  string(TOUPPER "${first}" first)
  string(TOLOWER "${rest}" rest)
  set(module_init_names ${module_init_names} "${first}${rest}tcl_Init")
endforeach(module)

# Now take those init functions and make a list of symbol declarations like:
# int Modulename_Init(Tcl_Interp*);
set(WRAP_ITK_TCL_LIBRARIES_INIT_DECLARATIONS )
foreach(module ${module_init_names})
  set(WRAP_ITK_TCL_LIBRARIES_INIT_DECLARATIONS "${WRAP_ITK_TCL_LIBRARIES_INIT_DECLARATIONS}  int ${module}(Tcl_Interp*);\n")
endforeach(module)

# Now we pack the addresses of the init function names into a comma-separated
# string, to be used in an array initializer
set(initializer )
foreach(module ${module_init_names})
  set(initializer "${initializer}  &${module},\n")
endforeach(module)
# Let's trim off that last ',\n':
string(REGEX REPLACE ",\n$" "" WRAP_ITK_TCL_LIBRARIES_ARRAY_INITIALIZER "${initializer}")

# Let's get the number of modules configured.
list(LENGTH WRAP_ITK_LIBRARIES WRAP_ITK_TCL_LIBRARIES_COUNT)

# And finally configure the file
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/itkTclModules.h.in
               ${CMAKE_CURRENT_BINARY_DIR}/itkTclModules.h
               @ONLY IMMEDIATE)

include_directories(${CMAKE_CURRENT_BINARY_DIR})
add_executable(itkwish itkTclAppInit.cxx)
foreach(module ${WRAP_ITK_LIBRARIES})
  target_link_libraries(itkwish ${module}Tcl)
endforeach(module)

target_link_libraries(itkwish ${TCL_LIBRARY} ${TK_LIBRARY})

# configure and install the driver itkwish script
set(WRAP_ITK_TCL_DIR "${CMAKE_INSTALL_PREFIX}/${WRAP_ITK_INSTALL_PREFIX}/Tcl")
set(WRAP_ITK_TCL_SWIG_DIR "${CMAKE_INSTALL_PREFIX}/${WRAP_ITK_INSTALL_PREFIX}/lib")
set(WRAP_ITK_TCL_ITKWISH_DIR "${CMAKE_INSTALL_PREFIX}/${WRAP_ITK_INSTALL_PREFIX}/bin")
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/itkwish.in
               ${CMAKE_CURRENT_BINARY_DIR}/InstallOnly/itkwish
               @ONLY IMMEDIATE )
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/InstallOnly/itkwish
  DESTINATION bin
  PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
)

# configure a itkwish usable in build tree
# use WrapITK_BINARY_DIR instead of the current bianry dir because tcl search pkgIndex.tcl in
# the subdirs before searching in the current dir, and so find the pikIndex.tcl file in InstallOnly
# first
set(WRAP_ITK_TCL_DIR "${WrapITK_BINARY_DIR}/Languages")
set(WRAP_ITK_TCL_SWIG_DIR "${LIBRARY_OUTPUT_PATH}")
set(WRAP_ITK_TCL_ITKWISH_DIR "${EXECUTABLE_OUTPUT_PATH}")
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/itkwish.in
               ${CMAKE_CURRENT_BINARY_DIR}/itkwish
               @ONLY IMMEDIATE )


#install the actual executable
install(TARGETS itkwish DESTINATION "${WRAP_ITK_INSTALL_PREFIX}/bin")
install(FILES itkinteraction.tcl itktesting.tcl itkdata.tcl itkutils.tcl
  DESTINATION "${WRAP_ITK_INSTALL_PREFIX}/Tcl"
)








macro(WRAP_LIBRARY_TCL library_name)
  set(WRAP_ITK_TCL_LIBRARY_DEPS )
  set(WRAP_ITK_TCL_LIBRARY_DECLS )
  set(WRAP_ITK_TCL_LIBRARY_CALLS )
  set(WRAP_ITK_TCL_CXX_FILES )
endmacro(WRAP_LIBRARY_TCL)


macro(END_WRAP_LIBRARY_TCL)

  # Loop over the extra swig input files and add them to the generated files
  # lists. Guess that the generated cxx output will have the same name as
  # the .i input file.
  foreach(source ${WRAPPER_LIBRARY_SWIG_INPUTS})
    get_filename_component(base_name ${source} NAME_WE)
    string(REPLACE "wrap_" "" base_name "${base_name}")
    WRAP_MODULE_TCL("${base_name}")
    END_WRAP_MODULE_TCL("${base_name}")
  endforeach(source)



  # create the tcl customization stuff in the main module
  # it allow to group the tcls module in a single shared lib, by loading the int
  # functions of the module. I also import the objects from the submodules in the
  # main module.
  #
  # It uses WRAP_ITK_TCL_LIBRARY_DECLS, WRAP_ITK_TCL_LIBRARY_CALLS
  configure_file("${WRAP_ITK_TCL_SOURCE_DIR}/main_module_ext.i.in"
    "${WRAPPER_MASTER_INDEX_OUTPUT_DIR}/tcl/${WRAPPER_LIBRARY_NAME}_ext.i"
    @ONLY IMMEDIATE)
  WRAP_ITK_INSTALL("/Configuration/Typedefs/tcl"
    "${WRAPPER_MASTER_INDEX_OUTPUT_DIR}/tcl/${WRAPPER_LIBRARY_NAME}_ext.i"
  )


  # set some var reused later
  set(interface_file "${WRAPPER_MASTER_INDEX_OUTPUT_DIR}/${WRAPPER_LIBRARY_NAME}.i")
  set(lib ${WRAPPER_LIBRARY_NAME}Tcl)
  set(cpp_file "${CMAKE_CURRENT_BINARY_DIR}/${WRAPPER_LIBRARY_NAME}Tcl.cpp")

  set(swig_command ${SWIG_EXECUTABLE})
  if(WRAP_ITK_USE_CCACHE)
    set(swig_command ${CCACHE_EXECUTABLE} ${swig_command})
  endif(WRAP_ITK_USE_CCACHE)

  # and generate c++ code from the main module swig interface.
  add_custom_command(
    OUTPUT ${cpp_file}
    COMMAND ${swig_command} -c++ -tcl -O -features autodoc=1 # -Werror
#       -fcompact
    -w509 # Overloaded method
    -w365 # operator+= ignored
    -w366 # operator-= ignored
    -w367 # operator*= ignored
    -w368 # operator/= ignored
    -w378 # operator!= ignored
    -w503 # Can't wrap 'operator []' unless renamed to a valid identifier.
    -w508 # Declaration of '???' shadows declaration accessible via operator->()
    ### TODO: remove that once the bug for std::vector is fixed ###
    -w401 # Maybe you forgot to instantiate 'XXX' using %template.
    ###
    -o ${cpp_file}
    -I${LANGUAGES_SRC_DIR}
    -I${WRAP_ITK_TYPEDEFS_DIRECTORY}/tcl
    -I${WRAP_ITK_TYPEDEFS_DIRECTORY}
    -outdir ${LIBRARY_OUTPUT_PATH}
    ${interface_file}
    WORKING_DIRECTORY ${WRAPPER_MASTER_INDEX_OUTPUT_DIR}/tcl
    DEPENDS ${DEPS} ${WRAP_ITK_TCL_LIBRARY_DEPS} ${interface_file} ${WRAPPER_MASTER_INDEX_OUTPUT_DIR}/tcl/${WRAPPER_LIBRARY_NAME}_ext.i ${SWIG_EXECUTABLE}
  )
  WRAP_ITK_INSTALL("/lib" "${tcl_file}")

  # build all the c++ files from this module in a common lib
  set(lib ${WRAPPER_LIBRARY_NAME}Tcl)
  add_library(${lib} SHARED ${cpp_file} ${WRAP_ITK_TCL_CXX_FILES} ${WRAPPER_LIBRARY_CXX_SOURCES})
  target_link_libraries(${lib} ${WRAPPER_LIBRARY_LINK_LIBRARIES} ${TCL_LIBRARY})
  add_dependencies(${lib} ${WRAPPER_LIBRARY_NAME}Swig)
  install(TARGETS "${lib}" DESTINATION "${WRAP_ITK_INSTALL_PREFIX}/lib")
  if(NOT EXTERNAL_WRAP_ITK_PROJECT)
    # don't depends on the targets from wrapitk in external projects
    foreach(dep ${WRAPPER_LIBRARY_DEPENDS})
      add_dependencies(${lib} ${dep}Swig)
    endforeach(dep)
  endif(NOT EXTERNAL_WRAP_ITK_PROJECT)

endmacro(END_WRAP_LIBRARY_TCL)


macro(END_WRAP_MODULE_TCL group_name)

  set(base_name wrap_${group_name})

  # the default typemaps, exception handler, and includes
  set(WRAP_ITK_TCL_SWIG_EXT "%import wrap_tclBase.i\n\n${WRAP_ITK_TCL_SWIG_EXT}")


  # create the swig interface for all the groups in the module
  #
  set(interface_file "${WRAPPER_MASTER_INDEX_OUTPUT_DIR}/${base_name}.i")
  set(lib ${group_name}Tcl)
  set(cpp_file "${CMAKE_CURRENT_BINARY_DIR}/${base_name}Tcl.cpp")

  # create the tcl customization for that wrap_*.cmake file.
  configure_file("${WRAP_ITK_TCL_SOURCE_DIR}/module_ext.i.in"
  "${WRAPPER_MASTER_INDEX_OUTPUT_DIR}/tcl/wrap_${group_name}_ext.i"
  @ONLY IMMEDIATE)
  WRAP_ITK_INSTALL("/Configuration/Typedefs/tcl" "${WRAPPER_MASTER_INDEX_OUTPUT_DIR}/tcl/wrap_${group_name}_ext.i"
  )

  # prepare dependencies
  set(DEPS )
  foreach(dep ${WRAPPER_LIBRARY_DEPENDS})
    set(DEPS ${DEPS} ${${dep}SwigFiles})
  endforeach(dep)

  set(swig_command ${SWIG_EXECUTABLE})
  if(WRAP_ITK_USE_CCACHE)
    set(swig_command ${CCACHE_EXECUTABLE} ${swig_command})
  endif(WRAP_ITK_USE_CCACHE)

  # and run swig to produce the c++ file and the .tcl file
  add_custom_command(
    OUTPUT ${cpp_file}
    COMMAND ${swig_command} -c++ -tcl -O -features autodoc=1 # -Werror
#       -fcompact
    -w509 # Overloaded method
    -w365 # operator+= ignored
    -w366 # operator-= ignored
    -w367 # operator*= ignored
    -w368 # operator/= ignored
    -w378 # operator!= ignored
    -w503 # Can't wrap 'operator []' unless renamed to a valid identifier
    -w508 # Declaration of '???' shadows declaration accessible via operator->()
    ### TODO: remove that once the bug for std::vector is fixed ###
    -w401 # Maybe you forgot to instantiate 'XXX' using %template.
    ###
    -o ${cpp_file}
    -I${LANGUAGES_SRC_DIR}
    -I${WRAP_ITK_TYPEDEFS_DIRECTORY}/tcl
    -I${WRAP_ITK_TYPEDEFS_DIRECTORY}
    -outdir ${LIBRARY_OUTPUT_PATH}
    ${interface_file}
    WORKING_DIRECTORY ${WRAPPER_MASTER_INDEX_OUTPUT_DIR}/tcl
    DEPENDS ${DEPS} ${interface_file} ${WRAPPER_MASTER_INDEX_OUTPUT_DIR}/tcl/${base_name}_ext.i ${SWIG_EXECUTABLE}
    # ${WRAP_ITK_TCL_LIBRARY_DEPS}
  )

# gcc visibility can't be used without getting errors when passing objects
# from one module to an other
#
#    if(CMAKE_COMPILER_IS_GNUCC)
#      set_target_properties(${lib} PROPERTIES COMPILE_FLAGS "-fvisibility=hidden")
#    endif(CMAKE_COMPILER_IS_GNUCC)

  # add the c++ files which will be generated by the swig command to the
  # list of tcl related c++ files, so they can be built at the end
  # of the current module.
  set(WRAP_ITK_TCL_CXX_FILES ${WRAP_ITK_TCL_CXX_FILES} ${cpp_file})

  # add needed files to the deps list
  set(WRAP_ITK_TCL_LIBRARY_DEPS ${WRAP_ITK_TCL_LIBRARY_DEPS} "${WRAPPER_MASTER_INDEX_OUTPUT_DIR}/tcl/${base_name}_ext.i" "${cpp_file}")

  # add this wrap_*.cmake stuff to the list of modules to init in the main module.
  # first the extern c declaration
  string(REGEX REPLACE "^(.)(.+)$" "\\1" first "${group_name}")
  string(REGEX REPLACE "^(.)(.+)$" "\\2" rest "${group_name}")
  string(TOUPPER "${first}" first)
  string(TOLOWER "${rest}" rest)
  set(capital_group_name "${first}${rest}tcl")
  set(WRAP_ITK_TCL_LIBRARY_DECLS "${WRAP_ITK_TCL_LIBRARY_DECLS}extern \"C\" int ${capital_group_name}_Init( Tcl_Interp* );\n")
  # and the call of the extern function
  set(WRAP_ITK_TCL_LIBRARY_CALLS "${WRAP_ITK_TCL_LIBRARY_CALLS}  ${capital_group_name}_Init( interp );\n")

endmacro(END_WRAP_MODULE_TCL group_name)



macro(ADD_ONE_TYPEDEF_TCL wrap_method wrap_class swig_name template_params)
endmacro(ADD_ONE_TYPEDEF_TCL)


macro(ADD_TCL_CONFIG_TEMPLATE base_name wrap_class swig_name template_params)
endmacro(ADD_TCL_CONFIG_TEMPLATE)


macro(WRAP_MODULE_TCL module)
  set(WRAP_ITK_TCL_SWIG_EXT "")
endmacro(WRAP_MODULE_TCL)


macro(WRAP_NAMED_CLASS_TCL class swig_name)
  # store the current class wrapped, so we can generate the typemaps for itk::ImageSource
  set(WRAP_ITK_TCL_CURRENT_CLASS "${class}")
  set(WRAP_ITK_TCL_CURRENT_SWIG_NAME "${swig_name}")
endmacro(WRAP_NAMED_CLASS_TCL)


macro(WRAP_TEMPLATE_TCL name types)
endmacro(WRAP_TEMPLATE_TCL name types)


macro(ADD_SIMPLE_TYPEDEF_TCL wrap_class swig_name)
  if("${wrap_class}" MATCHES "<.*>")
    string(REGEX REPLACE "^([^<]+)< *(.+) *>([^>]*)$" "\\1" cpp_name "${wrap_class}")
    string(REGEX REPLACE "^([^<]+)< *(.+) *>([^>]*)$" "\\2" template_params "${wrap_class}")
    string(REGEX REPLACE "^([^<]+)< *(.+) *>([^>]*)$" "\\3" ext_def "${wrap_class}")
  else("${wrap_class}" MATCHES "<.*>")
    set(cpp_name "${wrap_class}")
    set(template_params NO_TEMPLATE)
    set(ext_def "")
  endif("${wrap_class}" MATCHES "<.*>")
  string(REGEX REPLACE ".*::" "" simple_name "${cpp_name}")
#  message("${wrap_class} -- ${swig_name}")
#  message("${cpp_name} -- ${template_params} -- ${ext_def}")

# can't use that because std_vector.i complains loudly (with an error) about invalid superclass when that superclass is a std::vector
# not wrapped with %template
# but we can't declare them outside the current file without making swig use function defined outside
# TODO: reenable that once that bug is fixed
#
#   if("${cpp_name}" STREQUAL "itk::VectorContainer" AND NOT "${swig_name}" MATCHES "Pointer$")
#     # add a template definition for the superclass which is not in ITK
#     string(REGEX REPLACE "^[^,]+, *(.+) *$" "\\1" superclass_template_param "${template_params}")
#     if("${superclass_template_param}" MATCHES "::")
#       set(param "${superclass_template_param}")
#       string(REPLACE "::" "" superclass_template_param "${superclass_template_param}")
#       string(REPLACE "unsigned" "U" superclass_template_param "${superclass_template_param}")
#       string(REPLACE "signed" "S" superclass_template_param "${superclass_template_param}")
#       string(REPLACE "char" "C" superclass_template_param "${superclass_template_param}")
#       string(REPLACE "short" "S" superclass_template_param "${superclass_template_param}")
#       string(REPLACE "long" "L" superclass_template_param "${superclass_template_param}")
#       string(REPLACE "float" "F" superclass_template_param "${superclass_template_param}")
#       string(REPLACE "double" "D" superclass_template_param "${superclass_template_param}")
#       string(REPLACE " " "" superclass_template_param "${superclass_template_param}")
#       string(REPLACE "<" "" superclass_template_param "${superclass_template_param}")
#       string(REPLACE ">" "" superclass_template_param "${superclass_template_param}")
#       string(REPLACE "," "" superclass_template_param "${superclass_template_param}")
#       set(WRAP_ITK_TCL_SWIG_EXT "${WRAP_ITK_TCL_SWIG_EXT}%template(${swig_name}_Superclass) std::vector< ${superclass_template_param} >;\n")
#     endif("${superclass_template_param}" MATCHES "::")
#   endif("${cpp_name}" STREQUAL "itk::VectorContainer" AND NOT "${swig_name}" MATCHES "Pointer$")

# This part is useless because swig doesn't recognize that std::map< X, Y > is the same than
# std::map< X, Y, std::less< X > > and doesn't support a third parameter in the template
# specification.
# TODO: make a bugreport
#
#   if("${cpp_name}" STREQUAL "itk::MapContainer" AND NOT "${swig_name}" MATCHES "Pointer$")
#     # add a template definition for the superclass which is not in ITK
#     string(REGEX REPLACE "^[^,]+, *(.+) *$" "\\1" superclass_template_param "${template_params}")
#     if("${superclass_template_param}" MATCHES "::")
#       set(param "${superclass_template_param}")
#       string(REPLACE "::" "" superclass_template_param "${superclass_template_param}")
#       string(REPLACE "unsigned" "U" superclass_template_param "${superclass_template_param}")
#       string(REPLACE "signed" "S" superclass_template_param "${superclass_template_param}")
#       string(REPLACE "char" "C" superclass_template_param "${superclass_template_param}")
#       string(REPLACE "short" "S" superclass_template_param "${superclass_template_param}")
#       string(REPLACE "long" "L" superclass_template_param "${superclass_template_param}")
#       string(REPLACE "float" "F" superclass_template_param "${superclass_template_param}")
#       string(REPLACE "double" "D" superclass_template_param "${superclass_template_param}")
#       string(REPLACE " " "" superclass_template_param "${superclass_template_param}")
#       string(REPLACE "<" "" superclass_template_param "${superclass_template_param}")
#       string(REPLACE ">" "" superclass_template_param "${superclass_template_param}")
#       string(REPLACE "," "" superclass_template_param "${superclass_template_param}")
#       set(WRAP_ITK_TCL_SWIG_EXT "${WRAP_ITK_TCL_SWIG_EXT}%template(${swig_name}_Superclass) std::map< unsigned long, ${superclass_template_param}, std::less< unsigned long > >;\n")
#     endif("${superclass_template_param}" MATCHES "::")
#   endif("${cpp_name}" STREQUAL "itk::MapContainer" AND NOT "${swig_name}" MATCHES "Pointer$")
endmacro(ADD_SIMPLE_TYPEDEF_TCL)




###############################################################################
# Create the TclUtils library

if(NOT EXTERNAL_WRAP_ITK_PROJECT)
  subdirs(Tests)

  macro(END_WRAP_LIBRARIES_TCL)
#    add_subdirectory(${WRAP_ITK_TCL_SOURCE_DIR}/TclUtils)
  endmacro(END_WRAP_LIBRARIES_TCL)

  macro(WRAP_LIBRARIES_TCL)
    add_subdirectory(${WRAP_ITK_TCL_SOURCE_DIR}/TclBase)
  endmacro(WRAP_LIBRARIES_TCL)

else(NOT EXTERNAL_WRAP_ITK_PROJECT)
  macro(END_WRAP_LIBRARIES_TCL)
    # just do nothing
  endmacro(END_WRAP_LIBRARIES_TCL)

  macro(WRAP_LIBRARIES_TCL)
    # just do nothing
  endmacro(WRAP_LIBRARIES_TCL)

endif(NOT EXTERNAL_WRAP_ITK_PROJECT)

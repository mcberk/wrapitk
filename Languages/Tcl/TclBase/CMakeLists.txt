WRAP_LIBRARY("ITKTclBase" Tcl)

  set(WRAPPER_LIBRARY_DEPENDS )
  set(WRAPPER_LIBRARY_LINK_LIBRARIES )

  set(WRAPPER_LIBRARY_SWIG_INPUTS "${CMAKE_CURRENT_SOURCE_DIR}/wrap_tclBase.i")

  # no wrap_*.cmake file to include, no need to run that
  # AUTO_INCLUDE_MODULES()

END_WRAP_LIBRARY()

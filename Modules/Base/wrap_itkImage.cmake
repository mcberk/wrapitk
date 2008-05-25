WRAP_CLASS("itk::ImageBase" POINTER)
  FOREACH(d ${WRAP_ITK_DIMS})
    WRAP_TEMPLATE("${d}"  "${d}")
  ENDFOREACH(d)
END_WRAP_CLASS()

WRAP_CLASS("itk::Image" POINTER)
  SET(WRAPPER_TEMPLATES "${itk_Wrap_Image}")
END_WRAP_CLASS()

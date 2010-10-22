FILTER_DIMS(d2 2)
if(d2)
  WRAP_CLASS("itk::Rigid2DTransform" POINTER)
    WRAP_TEMPLATE("${ITKM_D}" "${ITKT_D}")
  END_WRAP_CLASS()
endif(d2)

FILTER_DIMS(d3 3)
if(d3)
  WRAP_CLASS("itk::Rigid3DTransform" POINTER)
    WRAP_TEMPLATE("${ITKM_D}" "${ITKT_D}")
  END_WRAP_CLASS()
endif(d3)


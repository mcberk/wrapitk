WRAP_CLASS("itk::Hessian3DToVesselnessMeasureImageFilter" POINTER)
  FILTER_DIMS(d3 3)
  IF(d3)
    FOREACH(t ${WRAP_ITK_SCALAR})
      WRAP_TEMPLATE("${ITKM_${t}}" "${ITKT_${t}}")
    ENDFOREACH(t)
  ENDIF(d3)
END_WRAP_CLASS()
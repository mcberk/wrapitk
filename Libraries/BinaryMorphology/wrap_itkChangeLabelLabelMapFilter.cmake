WRAP_CLASS("itk::ChangeLabelLabelMapFilter" POINTER)
  foreach(d ${WRAP_ITK_DIMS})
    WRAP_TEMPLATE("${ITKM_LM${d}}" "${ITKT_LM${d}}")
  endforeach(d)
END_WRAP_CLASS()

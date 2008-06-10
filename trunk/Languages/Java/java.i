
//######################################################################
// Includes

%include "typemaps.i"
%include "stl.i"

//######################################################################
// Some declarations

// Arrays
%include "carrays.i"
%array_functions(unsigned long, ULArray);
%array_functions(long, LArray);
%array_functions(int, IArray);
%array_functions(float, FArray);
%array_functions(double, DArray);
%array_class(unsigned long, ULArrayClass);
%array_class(long, LArrayClass);
%array_class(int, IArrayClass);
%array_class(float, FArrayClass);
%array_class(double, DArrayClass);

// String
//%template(StringVector) std::vector<std::string>;

// std::ostream
%ignore *::operator<<;
%ignore *::Print;
%extend itkLightObject
{
    std::string toString()
    {
        std::stringstream str;
        $self->Print(str);
        return str.str();
    }
    
    std::string Print()
    {
        std::stringstream str;
        $self->Print(str);
        return str.str();
    }
};

//######################################################################
// The ignore list

%ignore *::New();
%ignore *::CreateAnother();
%ignore *::Delete();
%ignore *::Register();
%ignore *::UnRegister();

//######################################################################
// Messing with the ctors
// Currently this is only used for vxl classes

/*
// By default swig-java creates protected constructors, when breaking the wrapping into

// packages, we need public, ie visible, constructors.

//%typemap(javabody) SWIGTYPE, SWIGTYPE *, SWIGTYPE &, SWIGTYPE [], SWIGTYPE (CLASS::*)

%typemap(javabody) SWIGTYPE

%{

  private long swigCPtr;

  private boolean swigCMemOwn;



  public $javaclassname(long cPtr, boolean cMemoryOwn) {

    swigCPtr = cPtr;

    swigCMemOwn = cMemoryOwn;

  }



  public static long getCPtr($javaclassname obj) {

    return (obj == null) ? 0 : obj.swigCPtr;

  }

%}

// And the ame goes for the derived classes

//%typemap(javabody_derived) SWIGTYPE, SWIGTYPE *, SWIGTYPE &, SWIGTYPE [], SWIGTYPE (CLASS::*)

%typemap(javabody_derived) SWIGTYPE

%{

  private long swigCPtr;

  private boolean swigCMemOwn;



  public $javaclassname(long cPtr, boolean cMemoryOwn) {

	  super(cPtr, cMemoryOwn);

  }

%}
*/
// more compact alternative
SWIG_JAVABODY_METHODS(public, public, SWIGTYPE)

//######################################################################
// Temporarily hosting itk-vtk stuff

// itkvtk, this is temp
%define TYPEMAP_ITKVTK_OUT(vtkClassType, vtkClassJava)
	%typemap(jstype) vtkClassType "vtk.vtkClassJava"
	%typemap(javaout) vtkClassType{
	    long cPtr = $jnicall;
	    if (cPtr == 0) return null;
	    vtk.vtkClassJava obj = null;
	    java.lang.ref.WeakReference ref = (java.lang.ref.WeakReference)vtk.vtkGlobalJavaHash.PointerToReference.get(new Long(cPtr));
	    if (ref != null) {
	      obj = (vtk.vtkClassJava)ref.get();
	    }
	    if (obj == null) {
	    	vtk.vtkClassJava tempObj = new vtk.vtkClassJava(cPtr);
	      String className = tempObj.GetClassName();
	      try {
	        Class c = Class.forName("vtk." + className);
	        java.lang.reflect.Constructor cons = c.getConstructor(new Class[] {long.class} );
	        obj = (vtk.vtkClassJava)cons.newInstance(new Object[] {new Long(cPtr)});
	      } catch (Exception e) {
	        e.printStackTrace();
	      }
	      tempObj.Delete();
	    }
	    return obj;
	}
%enddef

%define TYPEMAP_ITKVTK_IN(vtkClassType)
	%typemap(javain) vtkClassType "$javainput.GetVTKId()"
%enddef
// end itkvtk

//######################################################################
// Simulating smart pointers in SWIG
// This gets rid of wrapping ITK smart pointers.

// TODO: always tell swig we're the owner
// TODO: itk classes with no New() must be marked as abstract
%define DECLARE_REF_COUNT_CLASS_JAVA(itkClass)

	// Extend the itk classtype defined for wrapping to simulate a smart pointer in SWIG.
	// Also, make the ctor public to make the 'new' operator available in java
	%extend itkClass {
		public:
		itkClass() {
			typedef ::itk::SmartPointer<itkLightObject> Pointer;
			Pointer smtPtr = itkClass::New();
			itkClass *rawPtr = dynamic_cast<itkClass *>(smtPtr.GetPointer());
			rawPtr->Register();
			return rawPtr;
		};
		~itkClassWrapped() {
			self->UnRegister();
		};
	}
/*
	%typemap(out) itkClass *, itkClass & {
		if (ptrRaw) {
			ptrRaw->Register();
		}
		*(itkClass **)&$result = ptrRaw;
	}
*/	
	%typemap(out) itkClass##_Pointer, itkClass##_Pointer *, itkClass##_Pointer & {
		itkClass* ptrRaw = $1.GetPointer();
		if (ptrRaw) {
			ptrRaw->Register();
		}
		*(itkClass **)&$result = ptrRaw;
	}

	// Do not wrap the corresponding itkSmartPointer
	%ignore itkClass##_Pointer;

// itkvtk, this is temp
TYPEMAP_ITKVTK_OUT(vtkImageExport*, vtkImageExport)
TYPEMAP_ITKVTK_OUT(vtkImageImport*, vtkImageImport)
TYPEMAP_ITKVTK_OUT(vtkImageData*, vtkImageData)
TYPEMAP_ITKVTK_IN(vtkImageData*)
// end itkvtk

%enddef
#!/usr/bin/env python

# also test the import callback feature
def custom_callback(name, progress):
  if progress == 0:
    print >> sys.stderr, "Loading %s..." % name,
  if progress == 1:
    print >> sys.stderr, "done"
import itkConfig
itkConfig.ImportCallback = custom_callback

import itk, sys

# test the force load function
itk.force_load()

fileName = sys.argv[1]

PType = itk.US
dim = 2
IType = itk.Image[PType, dim]
ReaderType = itk.ImageFileReader[IType]
reader = ReaderType.New(FileName=fileName)


# test echo
itk.echo(reader)
itk.echo(reader, sys.stdout)

# test class_
assert itk.class_(reader) == ReaderType
assert itk.class_("dummy") == str

# test template
assert itk.template(ReaderType) == (itk.ImageFileReader, (IType,))
assert itk.template(reader) == (itk.ImageFileReader, (IType,))
try:
  itk.template(str)
  raise Exception("unknown class should send an exception")
except KeyError:
  pass

# test ctype
assert itk.ctype("unsigned short") == itk.US
assert itk.ctype("        unsigned      \n   short \t  ") == itk.US
try:
  itk.ctype("dummy")
  raise Exception("unknown C type should send an exception")
except KeyError:
  pass


# test output
assert itk.output(reader) == reader.GetOutput()
assert itk.output(1) == 1
# test the deprecated image
assert itk.image(reader) == reader.GetOutput()
assert itk.image(1) == 1


# test strel
# should work with the image type, an image instance or a filter
# and should work with a list, a tuple, an int or an itk.Size
for s in [2, (2, 2), [2, 2], itk.Size[2](2)] :
  st = itk.strel(dim, s)

  (tpl, param) = itk.template(st)
  assert tpl == itk.FlatStructuringElement
  assert param[0] == dim
  assert st.GetRadius()[0] == st.GetRadius()[1] == 2

# test size
s = itk.size(reader)
assert s[0] == s[1] == 256
s = itk.size(reader.GetOutput())
assert s[0] == s[1] == 256

# test physical size
s = itk.physical_size(reader)
assert s[0] == s[1] == 256.0
s = itk.physical_size(reader.GetOutput())
assert s[0] == s[1] == 256.0

# test spacing
s = itk.spacing(reader)
assert s[0] == s[1] == 1.0
s = itk.spacing(reader.GetOutput())
assert s[0] == s[1] == 1.0

# test origin
s = itk.origin(reader)
assert s[0] == s[1] == 0.0
s = itk.origin(reader.GetOutput())
assert s[0] == s[1] == 0.0

# test index
s = itk.index(reader)
assert s[0] == s[1] == 0
s = itk.index(reader.GetOutput())
assert s[0] == s[1] == 0

# test region
s = itk.region(reader)
assert s.GetIndex()[0] == s.GetIndex()[1] == 0
assert s.GetSize()[0] == s.GetSize()[1] == 256
s = itk.region(reader.GetOutput())
assert s.GetIndex()[0] == s.GetIndex()[1] == 0
assert s.GetSize()[0] == s.GetSize()[1] == 256


# test range
assert itk.range(reader) == (0, 255)
assert itk.range(reader.GetOutput()) == (0, 255)


# test write
itk.write(reader, sys.argv[2])
itk.write(reader, sys.argv[2], True)

# test search
res = itk.search("Index")
assert res[0] == "Index"
assert res[1] == "index"
assert "ContinuousIndex" in res

res = itk.search("index", True)
assert "Index" not in res


# test down_cast
obj = itk.Object.cast(reader)
assert obj.__class__ == itk.Object  # be sure that the reader is casted to itk::Object
down_casted = itk.down_cast(obj)
assert down_casted == reader
assert down_casted.__class__ == ReaderType

# pipeline, auto_pipeline and templated class are tested in other files

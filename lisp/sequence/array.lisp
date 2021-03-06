#|

  Fundamental Array Operations

  Copyright (c) 2011-2014, Odonata Research LLC

  Permission is hereby granted, free  of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction,  including without limitation the rights
  to use, copy, modify,  merge,  publish,  distribute,  sublicense, and/or sell
  copies of the  Software,  and  to  permit  persons  to  whom  the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and  this  permission  notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED  "AS IS",  WITHOUT  WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT  NOT  LIMITED  TO  THE  WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE  AND  NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT  HOLDERS  BE  LIABLE  FOR  ANY  CLAIM,  DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.

|#

(in-package :linear-algebra)

(defmethod norm ((data array) &optional (measure 1))
  "Return the norm of the array."
  (if (= 2 (array-rank data))
      (norm-array data measure)
      (error "Array rank(~D) must be 2."
             (array-rank data))))

(defmethod transpose ((data array))
  "Return the transpose of the array."
  (let* ((m-rows (array-dimension data 0))
         (n-columns (array-dimension data 1))
         (result
          (make-array
           (list n-columns m-rows)
           :element-type (array-element-type data))))
    (dotimes (row m-rows result)
      (dotimes (column n-columns)
        (setf (aref result column row) (aref data row column))))))

(defmethod ntranspose ((data array))
  "Replace the contents of the array with the transpose."
  (let ((m-rows (array-dimension data 0))
        (n-columns (array-dimension data 1)))
    (if (= m-rows n-columns)
        (dotimes (row m-rows data)
          (do ((column (1+ row) (1+ column)))
              ((>= column n-columns))
            (rotatef (aref data row column) (aref data column row))))
        (error "Rows(~D) and columns(~D) unequal."
               m-rows n-columns))))

(defmethod permute ((data array) (matrix permutation-matrix))
  (if (every #'= (array-dimensions data) (matrix-dimensions matrix))
      (right-permute data (contents matrix))
      (error "Array~A and permutation matrix~A sizes incompatible."
             (array-dimensions data) (matrix-dimensions matrix))))

(defmethod permute ((matrix permutation-matrix) (data array))
  (if (every #'= (array-dimensions data) (matrix-dimensions matrix))
      (left-permute (contents matrix) data)
      (error "Permutation matrix~A and array~A sizes incompatible."
             (matrix-dimensions matrix) (array-dimensions data))))

(defmethod scale ((scalar number) (data array))
  "Scale each element of the array."
  (let* ((m-rows (array-dimension data 0))
         (n-columns (array-dimension data 1))
         (result
          (make-array
           (list m-rows n-columns)
           :element-type (array-element-type data))))
    (dotimes (row m-rows result)
      (dotimes (column n-columns)
        (setf
         (aref result row column)
         (* scalar (aref data row column)))))))

(defmethod nscale ((scalar number) (data array))
  "Scale each element of the array."
  (let ((m-rows (array-dimension data 0))
        (n-columns (array-dimension data 1)))
    (dotimes (row m-rows data)
      (dotimes (column n-columns)
        (setf
         (aref data row column)
         (* scalar (aref data row column)))))))

(defmethod add ((array1 array) (array2 array) &key scalar1 scalar2)
  "Return the addition of the 2 arrays."
  (if (compatible-dimensions-p :add array1 array2)
      (add-array array1 array2 scalar1 scalar2)
      (error "The array dimensions, ~A,~A, are not compatible."
             (array-dimensions array1) (array-dimensions array2))))

(defmethod nadd ((array1 array) (array2 array) &key scalar1 scalar2)
  "Destructively add array2 to array1."
  (if (compatible-dimensions-p :add array1 array2)
      (nadd-array array1 array2 scalar1 scalar2)
      (error "The array dimensions, ~A,~A, are not compatible."
             (array-dimensions array1) (array-dimensions array2))))

(defmethod subtract ((array1 array) (array2 array) &key scalar1 scalar2)
  "Return the subtraction of the 2 arrays."
  (if (compatible-dimensions-p :add array1 array2)
      (subtract-array array1 array2 scalar1 scalar2)
      (error "The array dimensions, ~A,~A, are not compatible."
             (array-dimensions array1) (array-dimensions array2))))

(defmethod nsubtract ((array1 array) (array2 array) &key scalar1 scalar2)
  "Destructively subtract array2 from array1."
  (if (compatible-dimensions-p :add array1 array2)
      (nsubtract-array array1 array2 scalar1 scalar2)
      (error "The array dimensions, ~A and ~A, are not compatible."
             (array-dimensions array1) (array-dimensions array2))))

(defmethod product ((vector vector) (array array) &optional scalar)
  "Return a vector generated by the pre-multiplication of a array by a
vector."
  (if (compatible-dimensions-p :product vector array)
      (product-vector-array vector array scalar)
      (error "Vector(~D) is incompatible with array~A."
             (length vector) (array-dimensions array))))

(defmethod product ((array array) (vector vector) &optional scalar)
  "Return a vector generated by the multiplication of the array with a
vector."
  (if (compatible-dimensions-p :product array vector)
      (product-array-vector array vector scalar)
      (error "Array~A is incompatible with vector(~D)."
             (array-dimensions array) (length vector))))

(defmethod product ((array1 array) (array2 array) &optional scalar)
  "Return the product of the arrays."
  (if (compatible-dimensions-p :product array1 array2)
      (product-array-array array1 array2 scalar)
      (error "The array dimensions, ~A and ~A, are not compatible."
             (array-dimensions array1) (array-dimensions array2))))

(defmethod compatible-dimensions-p
    ((operation (eql :solve)) (array array) (vector vector))
  "Return true if the array dimensions are compatible for product."
  (and
   (= 2 (array-rank array))
   (= (array-dimension array 0)
      (array-dimension array 1)
      (length vector))))

(defmethod solve ((array array) (vector vector))
  "Return the solution to the system of equations."
  (if (compatible-dimensions-p :solve array vector)
      (gauss-solver (copy-array array) vector)
      (error "Array~A is incompatible with vector(~D)."
             (array-dimensions array) (length vector))))

(defmethod nsolve ((array array) (vector vector))
  "Return the solution to the system of equations."
  (if (compatible-dimensions-p :solve array vector)
      (gauss-solver array vector)
      (error "Array~A is incompatible with vector(~D)."
             (array-dimensions array) (length vector))))

(defmethod invert ((array array))
  "Return the invert of the array."
  (if (and
       (= 2 (array-rank array))
       (= (array-dimension array 0) (array-dimension array 1)))
      (gauss-invert (copy-array array))
      (error "Cannot invert array~A." array)))

(defmethod ninvert ((array array))
  "Return the invert of the array."
  (if (and
       (= 2 (array-rank array))
       (= (array-dimension array 0) (array-dimension array 1)))
      (gauss-invert array)
      (error "Cannot invert array~A." array)))

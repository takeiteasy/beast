;; Copyright (c) 2014, Eitaro Fukamachi
;; All rights reserved.

;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions are met:

;; * Redistributions of source code must retain the above copyright notice, this
;;   list of conditions and the following disclaimer.

;; * Redistributions in binary form must reproduce the above copyright notice,
;;   this list of conditions and the following disclaimer in the documentation
;;   and/or other materials provided with the distribution.

;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
;; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
;; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
;; SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
;; CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
;; OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
;; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

(in-package :event-emitter)

(defclass event-emitter ()
  ((silo :initform (make-hash-table :test 'eq)
         :accessor silo)))

(defstruct event-emitter*
  (silo (make-hash-table :test 'eq)))

(defstruct (listener (:constructor make-listener (function &key once)))
  function once)

(defun %add-listener (object event listener)
  (let* ((silo (silo object))
         (listeners (gethash event silo)))
    (if listeners
        (progn (vector-push-extend listener listeners)
               listeners)
        (setf (gethash event silo)
              (make-array 1 :element-type 'listener
                          :adjustable t :fill-pointer 1
                          :initial-contents (list listener))))))

(defun bind-listener (object event listener)
  (%add-listener object event (make-listener listener)))

(defun bind-listener-once (object event listener)
  (%add-listener object event (make-listener :once t)))

(defun unbind-listener (object event listener &key (start 0))
  (let* ((silo (silo object))
         (listeners (gethash event silo)))
    (unless listeners
      (return-from unbind-listener))
    (setf (gethash event silo)
          (delete listener listeners
                  :test #'eq
                  :count 1
		          :start start
                  :key #'listener-function)))
  (values))

(defun unbind-all-listeners (object &optional event)
  (if event
      (remhash event (silo object))
      (setf (silo object)
            (make-hash-table :test 'eq)))
  (values))

(defun broadcast-event (event object &rest args)
  (let* ((listeners (listeners object event))
         (max-size (length listeners)))
    (when (zerop max-size)
      (return-from broadcast-event nil))
    (do ((indx 0 (1+ indx)))
        ((>= indx max-size))
      (apply (listener-function (elt listeners indx)) args)
      (when (listener-once (elt listeners indx))
        (unbind-listener object event (listener-function (elt listeners indx))
                         :start indx)
        (decf max-size)
        (decf indx)))
    t))

(defun event-listeners (object event)
  (let* ((silo (silo object))
         (listeners (gethash event silo)))
    (or listeners
        (setf (gethash event silo)
              (make-array 0 :element-type 'listener
                          :adjustable t :fill-pointer 0)))))

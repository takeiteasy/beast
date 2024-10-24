(defpackage :event-emitter
  (:use :cl)
  (:export
   #:event-emitter
   #:event-emitter*

   #:bind-listener
   #:bind-listener-once
   #:unbind-listener
   #:unbind-all-listeners

   #:broadcast-event

   #:event-listeners))

(defpackage :beast
  (:use :cl :event-emitter)
  (:export
   #:entity
   #:entity-id

   #:define-entity

   #:create-entity
   #:destroy-entity
   #:clear-entities
   #:map-entities
   #:all-entities

   #:entity-created
   #:entity-destroyed

   #:define-aspect

   #:define-system))

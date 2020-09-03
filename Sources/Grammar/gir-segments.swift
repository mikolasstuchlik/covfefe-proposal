//
//  File.swift
//
//
//  Created by Mikoláš Stuchlík on 23/08/2020.
//

import Foundation

// https://gitlab.gnome.org/GNOME/gobject-introspection/-/raw/master/docs/gir-1.2.rnc

let gir_ignorables = #"""
default namespace core = "http://www.gtk.org/introspection/core/1.0"
namespace c = "http://www.gtk.org/introspection/c/1.0"
namespace glib = "http://www.gtk.org/introspection/glib/1.0"

"""#

let gir_doc_only = #"""
## doc a
   ## doc b

## doc c

"""#

let gir_grammar = #"""
default namespace core = "http://www.gtk.org/introspection/core/1.0"
namespace c = "http://www.gtk.org/introspection/c/1.0"
namespace glib = "http://www.gtk.org/introspection/glib/1.0"

grammar {
  start = Repository

  ## Root node of a GIR repository. It contains  namespaces, which can in turn be implemented in several libraries
  Repository =
    element repository {
      ## version number of the repository
      attribute version { xsd:string }?,
      ## prefixes to filter out from C identifiers for data structures and types. For example, GtkWindow will be Window. If c:symbol-prefixes is not used, then this element is used for both
      attribute c:identifier-prefixes { xsd:string }?,
      ## prefixes to filter out from C functions. For example, gtk_window_new will lose gtk_
      attribute c:symbol-prefixes { xsd:string }?,

      # Other elements a repository can contain
      (Include*
       & CInclude*
       & Package*
       & Namespace*)
    }

}

"""#

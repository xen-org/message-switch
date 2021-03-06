let config_mk = "config.mk"

let find_ocamlfind verbose name =
  let found =
    try
      let (_ : string) = Findlib.package_property [] name "requires" in
      true
    with
    | Not_found ->
        (* property within the package could not be found *)
        true
    | Findlib.No_such_package (_, _) ->
        false
  in
  if verbose then
    Printf.fprintf stderr "querying for ocamlfind package %s: %s" name
      (if found then "ok" else "missing") ;
  found

(* Configure script *)
open Cmdliner

let destdir =
  let doc = "Set the build root" in
  Arg.(value & opt string "" & info ["destdir"] ~docv:"DESTDIR" ~doc)

let bindir =
  let doc = "Set the directory for installing binaries" in
  Arg.(value & opt string "/usr/bin" & info ["bindir"] ~docv:"BINDIR" ~doc)

let sbindir =
  let doc = "Set the directory for installing superuser binaries" in
  Arg.(value & opt string "/usr/sbin" & info ["sbindir"] ~docv:"SBINDIR" ~doc)

let info =
  let doc = "Configures a package" in
  Term.info "configure" ~version:"0.1" ~doc

let output_file filename lines =
  let oc = open_out filename in
  let lines = List.map (fun line -> line ^ "\n") lines in
  List.iter (output_string oc) lines ;
  close_out oc

let configure destdir bindir sbindir =
  let async = find_ocamlfind false "async" in
  let lwt = find_ocamlfind false "lwt" in
  List.iter print_endline
    [
      "\nConfiguring with:"
    ; Printf.sprintf "\tdestdir=%s" destdir
    ; Printf.sprintf "\tbindir=%s" bindir
    ; Printf.sprintf "\tsbindir=%s" sbindir
    ; Printf.sprintf "\tasync=%s" (string_of_bool async)
    ; Printf.sprintf "\tlwt=%s" (string_of_bool lwt)
    ] ;
  (* Write config.mk *)
  let lines =
    [
      "# Warning - this file is autogenerated by the configure script"
    ; "# Do not edit"
    ; Printf.sprintf "DESTDIR=%s" destdir
    ; Printf.sprintf "BINDIR=%s" bindir
    ; Printf.sprintf "SBINDIR=%s" sbindir
    ; Printf.sprintf "ASYNC=--%s-async" (if async then "enable" else "disable")
    ; Printf.sprintf "LWT=--%s-lwt" (if lwt then "enable" else "disable")
    ]
  in
  output_file config_mk lines

let configure_t = Term.(pure configure $ destdir $ bindir $ sbindir)

let () =
  match Term.eval (configure_t, info) with `Error _ -> exit 1 | _ -> exit 0

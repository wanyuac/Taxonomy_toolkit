#!/usr/bin/env nextflow

/*
Modules for Taxonomy_toolkit

Copyright (C) 2020-2022 Yu Wan <wanyuac@126.com>
Licensed under the GNU General Public License v3.0
Publication: 7 June 2022; last modification: 7 June 2022
*/

def mkdir(dir_path) {  // Creates a directory and returns a File object
    def dir_obj = new File(dir_path)
    if ( ! dir_obj.exists() ) {
        result = dir_obj.mkdir()
        println result ? "Successfully created directory ${dir_path}" : "Cannot create directory ${dir_path}"
    } else {
        println "Directory ${dir_path} exists."
    }
    return dir_obj
}

import lldb
from os import path
import subprocess

def __lldb_init_module(debugger, internal_dict):
    lldb.SBDebugger.SetInternalVariable('target.process.thread.step-avoid-regexp',
                                        '^<?(std|core|alloc)::', debugger.GetInstanceName())
    
    debugger.HandleCommand("type format add --category Rust --format d 'char' 'signed char'")
    debugger.HandleCommand("type format add --category Rust --format u 'unsigned char'")
    
    command = ['rustc', '--print=sysroot']
    sysroot = subprocess.check_output(command, encoding="utf-8").strip()
    
    etc = path.join(sysroot, 'lib/rustlib/etc')
    lldb_lookup = path.join(etc, 'lldb_lookup.py')
    lldb_commands = path.join(etc, 'lldb_commands')
    
    debugger.HandleCommand(f"command script import '{lldb_lookup}'")
    debugger.HandleCommand(f"command source -s true '{lldb_commands}'")

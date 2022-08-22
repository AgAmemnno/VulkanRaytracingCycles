import bpy
import sys
import console_python

def clearConsole():
    for area in bpy.context.screen.areas:
        if area.type == 'CONSOLE':
            break

    for region in area.regions:
        if region.type == 'WINDOW':
            break

    #if a console has been used - otherwise the dictionary consoles might not exist
    print(sys.getrefcount(
        console_python.get_console.consoles.pop(hash(region))
        ))
    #&gt;&gt;&gt; 1

    context = bpy.context.copy()
    context['region'] = region
    context['area'] = area
    bpy.ops.console.clear(context)

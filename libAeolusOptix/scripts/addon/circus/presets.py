#
# Copyright 2011-2013 Blender Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# <pep8 compliant>

from bl_operators.presets import AddPresetBase
from bpy.types import Operator


class AddPresetIntegrator(AddPresetBase, Operator):
    '''Add an Integrator Preset'''
    bl_idname = "render.circus_integrator_preset_add"
    bl_label = "Add Integrator Preset"
    preset_menu = "CIRCUS_PT_integrator_presets"

    preset_defines = [
        "circus = bpy.context.scene.circus"
    ]

    preset_values = [
        "circus.max_bounces",
        "circus.diffuse_bounces",
        "circus.glossy_bounces",
        "circus.transmission_bounces",
        "circus.volume_bounces",
        "circus.transparent_max_bounces",
        "circus.caustics_reflective",
        "circus.caustics_refractive",
        "circus.blur_glossy"
    ]

    preset_subdir = "circus/integrator"


class AddPresetSampling(AddPresetBase, Operator):
    '''Add a Sampling Preset'''
    bl_idname = "render.cycles_sampling_preset_add"
    bl_label = "Add Sampling Preset"
    preset_menu = "CIRCUS_PT_sampling_presets"

    preset_defines = [
        "cycles = bpy.context.scene.cycles"
    ]

    preset_values = [
        "cycles.samples",
        "cycles.preview_samples",
        "cycles.aa_samples",
        "cycles.preview_aa_samples",
        "cycles.diffuse_samples",
        "cycles.glossy_samples",
        "cycles.transmission_samples",
        "cycles.ao_samples",
        "cycles.mesh_light_samples",
        "cycles.subsurface_samples",
        "cycles.volume_samples",
        "cycles.use_square_samples",
        "cycles.progressive",
        "cycles.seed",
        "cycles.sample_clamp_direct",
        "cycles.sample_clamp_indirect",
        "cycles.sample_all_lights_direct",
        "cycles.sample_all_lights_indirect",
    ]

    preset_subdir = "cycles/sampling"


classes = (
    AddPresetIntegrator,
    AddPresetSampling,
)


def register():
    from bpy.utils import register_class
    for cls in classes:
        register_class(cls)


def unregister():
    from bpy.utils import unregister_class
    for cls in classes:
        unregister_class(cls)


if __name__ == "__main__":
    register()

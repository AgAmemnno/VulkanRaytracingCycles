#pragma once

//#include "../pch.h"

#include <wrl/client.h>
#include <wrl/event.h>
#include <d3d11.h>
#include <d3d11_1.h>
#include <dxgi1_6.h>
#include <atomic>
#include <future>
#include <thread>
#include <condition_variable>
#include <functional>

namespace bonus {

    class PolySemousResource;

    struct Mitt {

        std::wstring name;
        DXGI_ADAPTER_DESC1   adapter_name;

        struct {
            float w, h;
            float scale;
            bool attach;
            bool is_primary;
        }resolution;
        struct {
            float t, b, l, r;
        }position;

        Microsoft::WRL::ComPtr<IDXGIOutput1>                O1;
        Microsoft::WRL::ComPtr<IDXGIAdapter1>              A1;
        Microsoft::WRL::ComPtr<ID3D11Device>                D11;
        Microsoft::WRL::ComPtr<ID3D11DeviceContext>    C11;

        Microsoft::WRL::ComPtr <IDXGIOutputDuplication> duplicant;
       
        void init();
        void setD11();
        void duplicate();
        void setO1Desc(Microsoft::WRL::ComPtr<IDXGIOutput1>   O1);
        
        /*
            for dxgi_output in d3dshot.dll.dxgi.discover_dxgi_outputs(dxgi_adapter) :
                dxgi_output_description = d3dshot.dll.dxgi.describe_dxgi_output(dxgi_output)

                if dxgi_output_description["is_attached_to_desktop"] :
                    display_device = display_device_name_mapping.get(dxgi_output_description["name"])

                    if display_device is None :
        display_device = ("Unknown", False)

            hmonitor = d3dshot.dll.user32.get_hmonitor_by_point(
                dxgi_output_description["position"]["left"],
                dxgi_output_description["position"]["top"]
            )

            scale_factor = d3dshot.dll.shcore.get_scale_factor_for_monitor(hmonitor)

            display = cls(
                name = display_device[0],
                adapter_name = dxgi_adapter_description,
                resolution = dxgi_output_description["resolution"],
                position = dxgi_output_description["position"],
                rotation = dxgi_output_description["rotation"],
                scale_factor = scale_factor,
                is_primary = display_device[1],
                hmonitor = hmonitor,
                dxgi_output = dxgi_output,
                dxgi_adapter = dxgi_adapter
            )

            displays.append(display)

        // Get output
        Microsoft::WRL::ComPtr<IDXGIOutput> DxgiOutput;
        hr = DxgiAdapter->EnumOutputs(output, DxgiOutput.GetAddressOf());

        if (FAILED(hr)) {
            return ProcessFailure(device, L"Failed to get specified output in DUPLICATIONMANAGER", L"Error", hr, EnumOutputsExpectedErrors);
        }

        DxgiOutput->GetDesc(&r.OutputDesc);

        HRESULT hr = S_OK;
        D3D_DRIVER_TYPE DriverTypes[] = {
            D3D_DRIVER_TYPE_HARDWARE,
            D3D_DRIVER_TYPE_WARP,
            D3D_DRIVER_TYPE_REFERENCE,
        };
        UINT NumDriverTypes = ARRAYSIZE(DriverTypes);

        // Feature levels supported
        D3D_FEATURE_LEVEL FeatureLevels[] = { D3D_FEATURE_LEVEL_11_0, D3D_FEATURE_LEVEL_10_1, D3D_FEATURE_LEVEL_10_0, D3D_FEATURE_LEVEL_9_1 };
        UINT NumFeatureLevels = ARRAYSIZE(FeatureLevels);

        D3D_FEATURE_LEVEL FeatureLevel;

        // Create device
        for (UINT DriverTypeIndex = 0; DriverTypeIndex < NumDriverTypes; ++DriverTypeIndex) {
            hr = D3D11CreateDevice(nullptr, DriverTypes[DriverTypeIndex], nullptr, 0, FeatureLevels, NumFeatureLevels, D3D11_SDK_VERSION,
                data.Device.GetAddressOf(), &FeatureLevel, data.DeviceContext.GetAddressOf());
            if (SUCCEEDED(hr)) {
                // Device creation success, no need to loop anymore
                break;
            }

        }
        if (FAILED(hr)) {
            return ProcessFailure(nullptr, L"Failed to create device in InitializeDx", L"Error", hr);
        }

    }
    */
    };

    struct Catcher {
        Mitt* mitt;
        PolySemousResource* pls;

        Microsoft::WRL::ComPtr<ID3D11Texture2D>   aquired;
        Microsoft::WRL::ComPtr<IDXGIResource>      Desktop;

        Microsoft::WRL::ComPtr<IDXGISurface>  surf;
        DXGI_MAPPED_RECT   src;

        Catcher();
        ~Catcher();
        void CatchOneShotNoBlocking();
        void polysemousTexture();

        bool Catch();
    };

    struct Pitcher {

        Catcher* catcher;
        std::function<void(BYTE* b)> OnFrame;
        std::atomic_bool  balk;
        std::condition_variable  fps90;

        Pitcher() {
            catcher = new Catcher;
        };
        ~Pitcher() {
            
            if (!balk.load()) {
                balk.exchange(true);
                fps90.notify_all();
            }
            printf("pitcher CG\n");
            delete catcher;
        };
        
        void Save(BYTE* p);
        uint64_t Pitch();
    };

    typedef std::future<uint64_t>        pitcherPlate;

};

#pragma once

#include "pch_mm.h"
#include "working_mm.h"





struct WindowVk {

	HWND                        window = NULL;
	HINSTANCE windowInstance;

	bool                         fullscreen;
	bool                          overlay;
	uint32_t width = 256;
	uint32_t height = 256;
	uint32_t frameCounter = 0;
	std::tstring     deviceName;


	~WindowVk() {
		PostDestroy();
	}

	LRESULT WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
	{
		///PAINTSTRUCT ps;
		///HDC hdc;

		switch (message)
		{
			/*
			case WM_COMMAND:
				for each (auto f in Command)
					if (f(LOWORD(wParam), HIWORD(wParam)))
						return 0;
				return DefWindowProc(hWnd, message, wParam, lParam);
			case WM_PAINT:
				hdc = BeginPaint(hWnd, &ps);
				for each (auto f in Paint) f(hdc);
				EndPaint(hWnd, &ps);
				break;
			case WM_LBUTTONDOWN: OnMouseDown(1, wParam, lParam); break;
			case WM_RBUTTONDOWN: OnMouseDown(2, wParam, lParam); break;
			case WM_MBUTTONDOWN: OnMouseDown(3, wParam, lParam); break;
			case WM_XBUTTONDOWN: OnMouseDown(3 + HIWORD(wParam), LOWORD(wParam), lParam); break;
			case WM_LBUTTONUP: OnMouseUp(1, wParam, lParam); break;
			case WM_RBUTTONUP: OnMouseUp(2, wParam, lParam); break;
			case WM_MBUTTONUP: OnMouseUp(3, wParam, lParam); break;
			case WM_XBUTTONUP: OnMouseUp(3 + HIWORD(wParam), LOWORD(wParam), lParam); break;
			case WM_MOUSEMOVE:
				for each (auto f in MouseMove)
					f(GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam), wParam);
				break;
				*/
		case WM_DESTROY:
			PostQuitMessage(0);
			break;
		default:
			return DefWindowProc(hWnd, message, wParam, lParam);
		}
		return 0;
	}
	void setSize(uint32_t  w, uint32_t h) {
		width = w;
		height = h;
		window = NULL;
	};

	void PostDestroy() {
		if (window) {

			//PostQuitMessage(0);
			DestroyWindow(window); window = nullptr;
			std::this_thread::sleep_for(std::chrono::milliseconds(10));
			window = NULL;

		}

	};

	HWND setupWindow(HINSTANCE hinstance, WNDPROC wndproc, std::tstring Name = "NoName")
	{

		std::tstring  name = Name;
		deviceName = Name;
		fullscreen = false;
		this->windowInstance = hinstance;

		WNDCLASSEX wndClass;


		wndClass.cbSize = sizeof(WNDCLASSEX);
		wndClass.style = CS_HREDRAW | CS_VREDRAW;
		wndClass.lpfnWndProc = wndproc;
		wndClass.cbClsExtra = 0;
		wndClass.cbWndExtra = 0;
		wndClass.hInstance = hinstance;
		wndClass.hIcon = LoadIcon(NULL, IDI_APPLICATION);
		wndClass.hCursor = LoadCursor(NULL, IDC_ARROW);
		wndClass.hbrBackground = (HBRUSH)GetStockObject(BLACK_BRUSH);
		wndClass.lpszMenuName = NULL;
		wndClass.lpszClassName = name.c_str();
		wndClass.hIconSm = LoadIcon(NULL, IDI_WINLOGO);

		if (!RegisterClassEx(&wndClass))
		{
			std::cout << "Could not register window class!\n";
			fflush(stdout);
			exit(1);
		}

		int screenWidth = GetSystemMetrics(SM_CXSCREEN);
		int screenHeight = GetSystemMetrics(SM_CYSCREEN);


		if (fullscreen)
		{
			DEVMODE dmScreenSettings;
			memset(&dmScreenSettings, 0, sizeof(dmScreenSettings));
			dmScreenSettings.dmSize = sizeof(dmScreenSettings);
			dmScreenSettings.dmPelsWidth = screenWidth;
			dmScreenSettings.dmPelsHeight = screenHeight;
			dmScreenSettings.dmBitsPerPel = 32;
			dmScreenSettings.dmFields = DM_BITSPERPEL | DM_PELSWIDTH | DM_PELSHEIGHT;

			if ((width != (uint32_t)screenWidth) && (height != (uint32_t)screenHeight))
			{
				if (ChangeDisplaySettings(&dmScreenSettings, CDS_FULLSCREEN) != DISP_CHANGE_SUCCESSFUL)
				{
					if (MessageBox(NULL, __T("Fullscreen Mode not supported!\n Switch to window mode?"), __T("Error"), MB_YESNO | MB_ICONEXCLAMATION) == IDYES)
					{
						fullscreen = false;
					}
					else
					{
						return nullptr;
					}
				}
			}

		}

		DWORD dwExStyle;
		DWORD dwStyle;

		if (fullscreen)
		{
			dwExStyle = WS_EX_APPWINDOW;
			dwStyle = WS_POPUP | WS_CLIPSIBLINGS | WS_CLIPCHILDREN;
		}
		else
		{
			dwExStyle = WS_EX_APPWINDOW | WS_EX_WINDOWEDGE;
			dwStyle = WS_OVERLAPPEDWINDOW | WS_CLIPSIBLINGS | WS_CLIPCHILDREN;
			//dwExStyle = WS_EX_APPWINDOW | WS_EX_LEFT;// WS_EX_WINDOWEDGE;
			//dwStyle = (WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX);// | WS_MAXIMIZEBOX);
		}

		RECT windowRect;
		windowRect.left = 0L;
		windowRect.top = 0L;
		windowRect.right = fullscreen ? (long)screenWidth : (long)width;
		windowRect.bottom = fullscreen ? (long)screenHeight : (long)height;

		AdjustWindowRectEx(&windowRect, dwStyle, FALSE, dwExStyle);

		uint32_t x = (GetSystemMetrics(SM_CXSCREEN) - windowRect.right) / 2;
		uint32_t y = (GetSystemMetrics(SM_CYSCREEN) - windowRect.bottom) / 2;

		window = CreateWindowEx(dwExStyle,
			name.c_str(),
			__T(""),
			dwStyle | WS_CLIPSIBLINGS | WS_CLIPCHILDREN,
			x,
			y + 100,
			windowRect.right - windowRect.left,
			windowRect.bottom - windowRect.top,
			NULL,
			NULL,
			hinstance,
			NULL);

		//SetWindowPos(window, 0, x, y+100, 0, 0, SWP_NOZORDER | SWP_NOSIZE);


		if (!window)
		{
			printf("Could not create window!\n");
			fflush(stdout);
			return nullptr;
			
		}

		ShowWindow(window, SW_SHOW);
		SetForegroundWindow(window);
		SetFocus(window);

		return window;
	}


	void  setWindowTitle(int FPS)
	{
		overlay = false;

		std::tstring device(deviceName);
		std::tstring windowTitle;
		windowTitle = __T("notitile - ") + device;
#ifdef UNICODE
		windowTitle += __T(" - ") + std::to_wstring(FPS) + __T(" fps");
#else
		windowTitle += __T(" - ") + std::to_string(FPS) + __T(" fps");
#endif


		SetWindowText(window, windowTitle.c_str());
	}


};


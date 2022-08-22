#include "pch.h"
#include "aeolus.hpp"


PyDoc_STRVAR(Aeolus_example_doc, "example(obj, number)Example function");

void handleMessages(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    switch (uMsg)
    {
    case WM_CLOSE:

        DestroyWindow(hWnd);
        PostQuitMessage(0);
        break;
    }
}

LRESULT CALLBACK WndProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    ///printf("handle window    %p   %u \n", hWnd, uMsg);
    handleMessages(hWnd, uMsg, wParam, lParam);
    return (DefWindowProc(hWnd, uMsg, wParam, lParam));
}



struct PyEnter {

    PyObject* func;

    void enter() {


        for (int i = 0; i < 10; i++) {
            log_file("callcount %d       this thread %u       \n", i, _threadid);
            auto state = PyGILState_Ensure();
            PyObject* res = (PyObject*)PyObject_CallFunction(func, "%s", "callback");
            PyGILState_Release(state);

            std::this_thread::sleep_for(std::chrono::milliseconds(100));
        };
        ///PyObject_Print(res, stdout, 0);
        ///printf("\n");
        ///log_mtPass2("Call ============================>draw_transform      cnt %zd  \n", obj->ob_base.ob_refcnt);
    };
};

///typedef int(__stdcall* f_funci)(ColorPy&);


typedef int(__stdcall* f_funcbi)(int);


PyObject* Aeolus_pythread(PyObject* self, PyObject* args, PyObject* kwargs) {

    PyObject* O;
    char* name;
    int          I;
    if (!PyArg_ParseTuple(args, "Osi", &O, &name, &I)) {
        return NULL;
    }
    /// HINSTANCE hGetProcIDDLL = LoadLibrary(L"D:\\Python\\Aeolus\\aeolus\\sample\\cl\\out\\Aeolus.dll");
    HINSTANCE hGetProcIDDLL = LoadLibrary(__T("D:\\C\\Aeolus\\packages\\dll\\test.dll"));
    if (!hGetProcIDDLL) {
        std::cout << "could not load the dynamic library" << std::endl;
        Py_RETURN_NONE;
    }

    // resolve function address here
   /// f_funcbi funcbi = (f_funcbi)GetProcAddress(hGetProcIDDLL, "funcbi");
    std::cout << "function is " << name << std::endl;
    F1ty_pO  funcbi = (F1ty_pO)GetProcAddress(hGetProcIDDLL, (const char*)name);
    //F1ty_pO  funcbi = (F1ty_pO)GetProcAddress(hGetProcIDDLL, "test");
    if (!funcbi) {
        std::cout << "could not locate the function" << std::endl;
        Py_RETURN_NONE;
    }


    std::cout << "funcbi() returned " << funcbi((Object3D*)O) << std::endl;


    /*
    PyEnter enter;
    enter.func = O;

    $des.beginThreads[name] = (HANDLE)_beginthreadex(
        NULL,
        1,
        DoEnter<PyEnter>,
        (void*)&enter,
        0,///CREATE_SUSPENDED,
        NULL
    );

    HINSTANCE hGetProcIDDLL = LoadLibrary(L"D:\\C\\AeolusDLL\\x64\\Release\\AeolusDLL.dll");

    if (!hGetProcIDDLL) {
        std::cout << "could not load the dynamic library" << std::endl;
        Py_RETURN_NONE;
    }

    // resolve function address here
    f_funci funci = (f_funci)GetProcAddress(hGetProcIDDLL, "funci");
    if (!funci) {
        std::cout << "could not locate the function" << std::endl;
        Py_RETURN_NONE;
    }

    ColorPy& color = *(ColorPy*)O;

    funci(color);
    std::cout << "funci() returned " << color.r << std::endl;
        */

    Py_RETURN_NONE;

};



PyObject* Aeolus_print(PyObject* self, PyObject* args, PyObject* kwargs) {


    Group* g = (Group*)PyTuple_GetItem(args, 0);
    Object3D* o = (Object3D*)PyTuple_GetItem(args, 1);

    g->child.emplace_back(std::move(o));

    log_file(" child %zu\n", g->child.size());

    Py_RETURN_NONE;

}
PyObject* Aeolus_undef(PyObject* self, PyObject* args, PyObject* kwargs) {

    char* print = (char*)"";
    static char keywords[][20] = { "print",NULL };
    if (!PyArg_ParseTupleAndKeywords(args, kwargs, "s", (char**)keywords, &print)) {
        return NULL;
    }
    std::string Print = std::string(print);
    if (Print == "Alloc") {
        $LivePrintOff = true;
    }
    front::heapQ<100> hq;// = { &_$hole.whack };


    Py_RETURN_NONE;

};
PyObject* Aeolus_listen(PyObject* self, PyObject* args, PyObject* kwargs) {

    uint64_t number = 0;


    PyObject* O;
    char* Name;
    char* fileName = (char*)"";

    if (!PyArg_ParseTuple(args, "s|s", &Name, &fileName)) {
        return NULL;
    }
    std::string  Mode = std::string(Name);

    static std::unordered_map< uintptr_t, uint32_t>  map;
    static long  mutex = 0;
    using cis = std::pair<const uintptr_t, uint32_t>;


    static bool ini = true;
    static  bool VRINIT = false;
    static  bool preempt = false;

    if (ini) {
        map.reserve(100000);
        mutex = 0;
        ini = false;
    }

    if (Mode == "CTX") {

        if (preempt)Py_RETURN_NONE;
        if ($device != VK_NULL_HANDLE) Py_RETURN_NONE;

        OVR* ovr = nullptr;

        if (!$tank.takeout(ovr, 0)) {
            log_bad(" not found  OVR.");
        };

        {
            uint32_t W = ovr->Width, H = ovr->Height;
            ///front::Synco* ctx_synco= new front::Synco;
            ContextVk* ctx = new ContextVk(W, H);
            {
                ctx->initialize();
                ctx->set$();
            }
            ObjectsVk* obj = new  ObjectsVk;
            ImagesVk* img = new  ImagesVk;
            VisibleObjectsVk* vobj = new  VisibleObjectsVk;
            AttachmentsVk* atta = new  AttachmentsVk(W, H, 2);
            {
                atta->createMultiViewColorDepthWithResolution();
            }
            PipelineVk* pipe = new  PipelineVk;

            {
                $tank.add(std::move(ctx));
                $tank.add(std::move(obj));
                $tank.add(std::move(img));
                $tank.add(std::move(vobj));
                $tank.add(std::move(atta));
                $tank.add(std::move(pipe));
            }
            log_file("CTX   %p  device   keep alive %p    \n", ctx, $device);

            {
                des.ToDoList(
                    [pipe = std::move(pipe)](bool del) mutable {

                    log_file(" PipelineVk do %s .  Contents  %p  \n", ((del) ? "Delete" : "Valid"), pipe);
                    if (del) {
                        types::deleteRaw(pipe);
                    }
                    return !(pipe == nullptr);
                });

                des.ToDoList(
                    [atta = std::move(atta)](bool del) mutable {

                    log_file(" AttachmentsVk do %s .  Contents  %p  \n", ((del) ? "Delete" : "Valid"), atta);
                    if (del) {
                        types::deleteRaw(atta);
                    }
                    return !(atta == nullptr);
                });

                des.ToDoList(
                    [img = std::move(img)](bool del) mutable {

                    log_file("ImagesVk do %s .  Contents  %p  \n", ((del) ? "Delete" : "Valid"), img);
                    if (del) {
                        types::deleteRaw(img);
                    }
                    return !(img == nullptr);
                });

                des.ToDoList(
                    [vobj = std::move(vobj)](bool del) mutable {

                    log_file("VisibleObjectsVk do %s .  Contents  %p  \n", ((del) ? "Delete" : "Valid"), vobj);
                    if (del) {
                        types::deleteRaw(vobj);
                    }
                    return !(vobj == nullptr);
                });
                des.ToDoList(
                    [obj = std::move(obj)](bool del) mutable {

                    log_file("ObjectsVk do %s .  Contents  %p  \n", ((del) ? "Delete" : "Valid"), obj);
                    if (del) {
                        types::deleteRaw(obj);
                    }
                    return !(obj == nullptr);
                });
                des.ToDoList(
                    [ctx = std::move(ctx)](bool del) mutable {

                    log_file("ContextVk do %s .  Contents  %p  \n", ((del) ? "Delete" : "Valid"), &ctx);
                    if (del) {
                        types::deleteRaw(ctx);
                    }
                    return !(ctx == nullptr);
                });
            }
            preempt = true;
        }


        Py_RETURN_NONE;

    }
    else if (Mode == "OVR") {
        
    

       if (VRINIT)Py_RETURN_NONE;

        {
            OVR* ovr = new OVR;
            {
                ovr->VrInit();
            }

            log_file("OVR   device   keep alive  %p    \n", ovr);

            des.ToDoList(
                [ctx = std::move(ovr)](bool del) mutable {
                if (del) {
                    types::deleteRaw(ctx);
                }
                return !(ctx == nullptr);
            });

            $tank.add(std::move(ovr));

            VRINIT = true;

        }

        Py_RETURN_NONE;

    }

    Py_RETURN_NONE;

};





static PyMethodDef Aeolus_functions[] = {
     { "write", (PyCFunction)Aeolus_print, METH_VARARGS, Aeolus_example_doc },
    { "undef", (PyCFunction)Aeolus_undef, METH_VARARGS | METH_KEYWORDS, Aeolus_example_doc },
    { "syncotank", (PyCFunction)Aeolus_listen, METH_VARARGS | METH_KEYWORDS, Aeolus_example_doc },
      { "callback", (PyCFunction)Aeolus_pythread, METH_VARARGS | METH_KEYWORDS, Aeolus_example_doc },
    { NULL, NULL, 0, NULL }
};


int exec_Aeolus(PyObject* module) {

    PyModule_AddFunctions(module, Aeolus_functions);
    PyModule_AddStringConstant(module, "__author__", "kaz38");
    PyModule_AddStringConstant(module, "__version__", "1.0.0");
    PyModule_AddIntConstant(module, "year", 2020);

    return 0; /* success */
}


PyDoc_STRVAR(Aeolus_doc, "The Aeolus module");


static PyModuleDef_Slot Aeolus_slots[] = {
    { Py_mod_exec, exec_Aeolus },
    { 0, NULL }
};

void  Aeolus_free(void* p) {


    $des.Holocaust();


    log_file("Aeolus Free\n");

};

static PyModuleDef Aeolus_def = {
    PyModuleDef_HEAD_INIT,
    "cthreepy",
    Aeolus_doc,
    0, /// -1,              /* m_size */
    NULL, ///Aeolus_functions,           /* m_methods */
    Aeolus_slots,
    NULL,           /* m_traverse */
    NULL,           /* m_clear */
    Aeolus_free,           /* m_free */
};
static PyModuleDef Aeolus_definition = {
    PyModuleDef_HEAD_INIT,
    "cthreepy",
    "A  Python  module that prints 'hello world' from C code.",
    -1,
    Aeolus_functions,
    0,
    0,
    0,
    Aeolus_free,           /* m_free */
};


PyMODINIT_FUNC PyInit_cthreepy() {

    PolicyAllocateFree();
    $des.Dispatch();

#ifdef _DEBUG
    _CrtSetDbgFlag(_CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF);
#endif

    ///PyObject* m = PyModuleDef_Init(&Aeolus_def);

    Py_Initialize();
    PyObject* m = PyModule_Create(&Aeolus_definition);

    /*
    if (AddType_ColorPy(m) != 0)return NULL;
    if (AddType_PreProcessPassVk(m) != 0)return NULL;

    if (AddType_TOPICS(m) != 0)return NULL;
    if (AddType_Event_Ctrl(m) != 0) return NULL;
    */

    if (AddType_Topics(m) != 0)return NULL;
    if (AddType_CanvasVk(m) != 0)return NULL;

    if (AddType_Materials(m) != 0)return NULL;
    if (AddType_Object3D(m) != 0)return NULL;
    if (AddType_BufferAttribute(m) != 0)return NULL;

    if (AddType_Camera(m) != 0)return NULL;


    if (AddType_Scene(m) != 0)return NULL;
    if (AddType_Overlay(m) != 0)return NULL;
    if (AddType_Group(m) != 0) return NULL;



    if (AddType_Color(m) != 0)return NULL;
    if (AddType_Matrix3(m) != 0) return NULL;
    if (AddType_Matrix4(m) != 0)return NULL;

    if (AddType_Vector2(m) != 0)return NULL;
    if (AddType_Vector3(m) != 0)return NULL;
    if (AddType_Quaternion(m) != 0)return NULL;
    if (AddType_Euler(m) != 0)return NULL;
    if (AddType_Sphere(m) != 0)return NULL;
    if (AddType_Plane(m) != 0)return NULL;
    if (AddType_Frustum(m) != 0)return NULL;

    if (AddType_ListnerPy(m) != 0)return NULL;




    return m;

}

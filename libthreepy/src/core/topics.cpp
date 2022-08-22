#pragma once
#include "pch_three.h"
#include "math/common.hpp"
#include "materials/common.hpp"
#include "common.hpp"
#include "topics.h"
#include "canvas.h"
#include "scene/scene.h"

using namespace aeo;


#define isPOLLING(type)   __ENUM__(type, arth::TOPICS::POLLING_BIT)
#define RENDERMODEL_PATH(model)  ("C:/Program Files (x86)/Steam/steamapps/common/SteamVR/resources/rendermodels/" + model).c_str()



static int
init(Topics* self, PyObject* args, PyObject* kwds)
{
	char* title = nullptr;
	char* tip   = nullptr;
	PyArg_ParseTuple(args, "ss", &title, &tip);
	self->title  = std::string(title);
	self->tip    = std::string(tip);
	self->rmodel = false;
	self->show = false;
	return 0;
};


static void
Topics_dealloc(Topics* self)
{

	Py_TYPE(self)->tp_free((PyObject*)self);
};


static int
Topics_init(Topics* self, PyObject* args, PyObject* kwds)
{
	static  uint32_t TPCID = 0;
	TPCID++;
	self->type = arth::TOPICS::RAW;
	
	self->FLAG = {};


	init(self, args, kwds);
	
	return 0;
}


static PyObject*
Topics_new(PyTypeObject* type, PyObject* args, PyObject* kw)
{
	int rc = -1;
	//printf("<Topics>  new \n");
	Topics* self = NULL;
	self = (Topics*)type->tp_alloc(type, 0);
	if (!self) goto error;
	rc = 0;
error:
	if (rc < 0)Py_XDECREF(self);
	return (PyObject*)self;

}



template<class T>
static PyObject*
Topics_getTopic(T* self, void* closure)
{
	//Py_INCREF( (PyObject *) self);
	return  (PyObject*)PyBool_FromLong((self->dash) ? 1 : 0);
}

template<class T>
static int
Topics_setDash(T* self, PyObject* vec, void* closure)
{
	self->dash =  (bool) ((PyLong_AsLong(vec)==0) ? false:true);
	return 0;
}


template<class T>
static int
Topics_setRModel(T* self, PyObject* vec, void* closure)
{
	self->rmodel  = (bool)((PyLong_AsLong(vec) == 0) ? false : true);
	return 0;
}


template<class T>
static PyObject*
Topics_getVISIBLEMODE(T* self, void* closure)
{
	//Py_INCREF( (PyObject *) self);
	return  (PyObject*)PyLong_FromLong(self->visible_mode);
}


template<class T>
static int
Topics_setVISIBLEMODE(T* self, PyObject* vec, void* closure)
{
	self->visible_mode = PyLong_AsLong(vec);
	return 0;
}

template<class T>
static PyObject*
Topics_getWIDTH(T* self, void* closure)
{
	//Py_INCREF( (PyObject *) self);
	return  (PyObject*)PyFloat_FromDouble((double)self->width);
}

template<class T>
static int
Topics_setWIDTH(T* self, PyObject* vec, void* closure)
{
	self->width = (float)PyFloat_AsDouble(vec);
	return 0;
}



template<class T>
static int
Topics_setPOLLING(T* self, PyObject* vec, void* closure)
{
	if ( (self->type & arth::TOPICS::POLLING_BIT) != arth::TOPICS::POLLING_BIT) {
		self->type = self->type | (arth::TOPICS::POLLING_BIT);
	}
	
	return 0;
}


template<class T>
static PyGetSetDef Topics_getsetters[] = {
	  {(char*)"width", (getter)Topics_getWIDTH<T>, (setter)Topics_setWIDTH<T>,0,0},
	  {(char*)"isDash", (getter)Topics_getTopic<T>, (setter)Topics_setDash<T>,0,0},
	   {(char*)"isRModel", 0, (setter)Topics_setRModel<T>,0,0},
	  {(char*)"isPolling", 0, (setter)Topics_setPOLLING<T>,0,0},
	  {(char*)"visible_mode", (getter)Topics_getVISIBLEMODE<T>, (setter)Topics_setVISIBLEMODE<T>,0,0},
	 {0}
};


template<class T>
PyMethodDef  Topics_tp_methods[] = {
	{0},
};

template<class T>
PyTypeObject tp_Topics = []() -> PyTypeObject {

	PyTypeObject type = { PyVarObject_HEAD_INIT(0, 0) };
	type.tp_name = "cthreepy.Topics";
	type.tp_doc = "Topics objects";
	type.tp_basicsize = sizeof(T);
	type.tp_itemsize = 0;
	type.tp_flags = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE;
	type.tp_new = Topics_new;
	type.tp_init = (initproc)Topics_init;
	type.tp_methods = Topics_tp_methods<T>;
	type.tp_dealloc = (destructor)Topics_dealloc;
	type.tp_getset = Topics_getsetters<T>;
	return type;

}();



inline static bool BOOL_BIT(uint32_t bit,uint32_t f) {
	return ((f >> (bit)) & 1);
}

inline static void ASSIGN_BIT(uint32_t bit, bool tf, uint32_t& f) {
	if (tf) f = f | (1 << bit);
	else   f = f & (~(1<<bit));
}




void Topics::getRotationToPoint(Vector3* f_pointA, Vector3* f_pointB, Quaternion* f_rotationA, Quaternion* f_result)
{

	Vector3 g_AxisY(0., 1., 0.);
	Vector3 l_dir, l_up, l_crossA, l_crossB;

	l_dir.copy(f_pointA)->sub(f_pointB)->normalize();
	l_up.copy(&g_AxisY)->applyQuaternion(f_rotationA);
	l_crossA.crossVectors(&l_up, &l_dir)->normalize();
	l_crossB.crossVectors(&l_dir, &l_crossA)->normalize();

	f_result->setFromRotationMatrix(&l_crossA, &l_crossB, &l_dir);

}

float Topics::transform1(Object3D* self, Object3D* head, Object3D* hand) {


	Vector3 g_AxisZN(0., 0., -1.);
	const Vector2 g_ViewAngleRange(M_PI / 6.f, M_PI / 12.f);
	const double g_ViewAngleRangeDiff = (g_ViewAngleRange.x - g_ViewAngleRange.y);

	Vector3 scale(1, 1, 1);
	double opacity;

	Vector3 HandDir;
	HandDir.copy(hand->position)->sub(head->position)->normalize();
	Vector3 ViewDir;
	ViewDir.copy(&g_AxisZN)->applyQuaternion(head->quaternion);


	opacity = HandDir.dot(&ViewDir);
	opacity = acos(opacity);
	opacity = std::clamp(opacity, g_ViewAngleRange.y, g_ViewAngleRange.x);
	opacity = 1. - ((opacity - g_ViewAngleRange.y) / g_ViewAngleRangeDiff);

	//ms_vrOverlay->SetOverlayAlpha(m_overlayHandle, l_opacity);
   // Set rotation based on direction to HMD
	Quaternion l_rot;
	getRotationToPoint(head->position, hand->position, head->quaternion, &l_rot);


	self->matrixWorld->compose(hand->position, &l_rot, &scale);

	self->matrixWorld->multiply(self->matrix);

	return (float)opacity;
};

void Topics::init(uint32_t did) {
#ifdef  ENABLED_VULKAN_OV
	deviceID  = did;
	OVov = vr::VROverlay();

	if (dash) {

		OVov->CreateDashboardOverlay(title.c_str(), tip.c_str(), &Main, &Logo);
		OVov->SetOverlayFromFile(Logo,  IMAGE_PATH "icons0\\i.png");
		OVov->SetOverlayFlag(Main, vr::VROverlayFlags_SortWithNonSceneOverlays, true);
		OVov->SetOverlayFlag(Main, vr::VROverlayFlags_VisibleInDashboard, true);
	}
	else {

		if (OVov->CreateOverlay(title.c_str(), tip.c_str(), &Main) == vr::VROverlayError_None) {};
		if (visible_mode == MARK_SHOW_DASH_OFF) {
			OVov->SetOverlayFlag(Main, vr::VROverlayFlags_SortWithNonSceneOverlays, false);
			OVov->SetOverlayFlag(Main, vr::VROverlayFlags_VisibleInDashboard, false);
		}
		//char name[256];
		//vr::VROverlayError pError;
		//OVov->GetOverlayName(Main, name, 256, &pError);

		/*
		if (visible_mode == MARK_SHOW_DASH_ON) {
			OVov->SetOverlayFlag(Main, vr::VROverlayFlags_SortWithNonSceneOverlays, true);
			OVov->SetOverlayFlag(Main, vr::VROverlayFlags_VisibleInDashboard, true);
		}

	};
	OVov->SetOverlayInputMethod(Main, vr::VROverlayInputMethod_Mouse);
	OVov->SetOverlayFlag(Main, vr::VROverlayFlags_ProtectedContent, false);
	*/
	}


	OVov->SetOverlayWidthInMeters(Main, width);
	visible  = true;
	fuid     = 2;
#endif
}
#ifdef  ENABLED_VULKAN_OVR 
void Topics::update(Object3D* self, vr::Texture_t* texture) {
	

	static vr::HmdMatrix34_t Transform0 = {
												1.0f, 0.0f, 0.0f, 0,
												0.0f, 1.0f, 0.0f, 0,
												0.0f, 0.0f, 1.0f, -2.0f
	};

	if (visible) {

		OVov = vr::VROverlay();

		OVov->SetOverlayTexture(Main, texture);


		if (!show) {
			OVov->ShowOverlay(Main);
			show = true;
		  }
		}
	
};
#endif
void Topics::update(Object3D* self,bool Dash) {

#ifdef  ENABLED_VULKAN_OVR
	if (visible) {
       
		if(!BOOL_BIT(fuid,FLAG.INIT) ){
			Material* material = (Material*)(self->material);
			if (material->names->spv == MARK_DesignedSprite) {
				OVov->SetOverlayFromFile(Main, (IMAGE_PATH + material->names->imageName).c_str());
			}else if (material->names->spv == MARK_ObjFile) {

				Log_once("RenderModel    Set       %s   \n", RENDERMODEL_PATH(title));
				//OVov->SetOverlayRenderModel(Main, RENDERMODEL_PATH(title),nullptr);
			}else {
				//OVov->SetOverlayTexelAspect(Main,  1920.f / 1080.f);
				vr::HmdVector2_t  vec2;
				vec2.v[0] = 1920.f; vec2.v[1] = 1080.f;

				OVov->SetOverlayMouseScale(Main, &vec2);
				//OVov->SetOverlayCurvature(Main, 1.414f);
			}
			if (visible_mode <= MARK_SHOW_DASH_ONOFF) {
				OVov->ShowOverlay(Main);
				ASSIGN_BIT(fuid, true, FLAG.CACHE);
			}
			else {
				OVov->HideOverlay(Main);
				ASSIGN_BIT(fuid, false, FLAG.CACHE);
			}
			ASSIGN_BIT(fuid, true, FLAG.INIT);
			
			//OVov->SetOverlayFromFile(Main, (std::string(IMAGE_PATH) + file).c_str());
			//OVov->ShowOverlay(Main);
		}

		if (dash && Dash) show = true;
		else if (!dash) {
				if (visible_mode == MARK_SHOW_DASH_ONOFF)show = true;
				else if (visible_mode == MARK_SHOW_DASH_ON && Dash)show = true;
				else if (visible_mode == MARK_SHOW_DASH_OFF && !Dash)show = true;
		}

		if (BOOL_BIT(fuid, FLAG.CACHE) != show) {
			ASSIGN_BIT(fuid, show, FLAG.CACHE);
			if (show)OVov->ShowOverlay(Main);
			else OVov->HideOverlay(Main);
		
		}
		if (!dash) {
			Material* material = (Material*)(self->material);
			if (material->names->spv == MARK_ObjFile) {
				static  bool  ini = true;
				/*
				static vr::HmdMatrix34_t Transform0 = { 1.0f, 0.0f, 0.0f, 0,
																				0.0f, 1.0f, 0.0f, 0,
																				0.0f, 0.0f, 1.0f, 0.0f };
				Log_once("RenderModel    Set       %s       %u   \n", title.c_str(), deviceID);
				OVov->SetOverlayTransformTrackedDeviceRelative(Main, 1, &Transform0);
				*/
				static vr::HmdMatrix34_t Transform0 = { 1.0f, 0.0f, 0.0f, 0,
																					0.0f, 1.0f, 0.0f, 0,
																					0.0f, 0.0f, 1.0f, -2.0f };
				OVov->SetOverlayTransformAbsolute(Main, vr::TrackingUniverseStanding, &Transform0);
				if (ini) {
					//OVov->SetOverlayRenderModel(Main, title.c_str(), nullptr);
					OVov->ShowOverlay(Main);
					ini = false;
				}
			
				
				
			}else if (self->parent != nullptr) {

				Scene* scene = (Scene*)(self->parent->deriv);
				///Matrix34FromThree(scene->page->matrixWorld, Transform);
				
				OVov->SetOverlayAlpha(Main, float(scene->page->opacity));
				///printMatrix4("TopicMatrix", scene->page->matrixWorld->elements);
				///printMatrix34("Transform", Transform.m);

				//OVov->SetOverlayTransformAbsolute(Main, vr::TrackingUniverseRawAndUncalibrated,&Transform);
				OVov->SetOverlayTransformAbsolute(Main, vr::TrackingUniverseStanding, &Transform);
				//OVov->SetOverlayTransformAbsolute(Main, vr::TrackingUniverseSeated, &Transform);
			}
			else {

				static vr::HmdMatrix34_t Transform0 = { 1.0f, 0.0f, 0.0f, 0,
																					0.0f, 1.0f, 0.0f, 0,
																					0.0f, 0.0f, 1.0f, -2.0f };
				OVov->SetOverlayTransformAbsolute(Main, vr::TrackingUniverseStanding, &Transform0);
			}

		}
	}
#endif


};








int AddType_Topics(PyObject* m) {

	if (PyType_Ready(&tp_Topics<Topics>) < 0)
		return -1;
	Py_XINCREF(&tp_Topics<Topics>);
	PyModule_AddObject(m, "Topics", (PyObject*)&tp_Topics<Topics>);
	return 0;
}


int AddType_TOPICS(PyObject* m) {
	if (AddType_Topics(m) != 0)return -1;
	//if (AddType_TopicsServer(m) != 0)return -1;
	return 0;
};

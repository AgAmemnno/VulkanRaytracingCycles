#include "pch_three.h"
#include "common.hpp"

using namespace aeo;

static Vector3                         up;




#define Log_NO_O3D
#ifdef Log_NO_O3D
#define Log_o3d(...)
#else
#define Log_o3d(...) Log_out(__FILE__, __LINE__, Log_TRACE, __VA_ARGS__)
#endif


const  Vector3  DefaultUp  =     Vector3(0, 1, 0);
static Vector3   _target = Vector3(0, 0, 0);
static Vector3  _position = Vector3(0, 0, 0);
static Vector3  _v1          = Vector3(0, 0, 0);
static Matrix4    _m1;
static Quaternion _q1;
static Vector3 _xAxis = Vector3(1, 0, 0);
static Vector3 _yAxis = Vector3(0, 1, 0);
static Vector3 _zAxis = Vector3(0, 0, 1);


void Object3D::lookAt(Vector3* v) {

	// This method does not support objects having non-uniformly-scaled parent(s)

	_target.copy(v);

	updateWorldMatrix(true, false);

	_position.setFromMatrixPosition(matrixWorld);

	if (type == arth::Object::Camera || type == arth::Object::Light) {

		_m1.lookAt(&_position, &_target, &up);

	}
	else {

		_m1.lookAt(&_target, &_position, &up);

	}


	quaternion->setFromRotationMatrix(&_m1);

	if (parent) {

		_m1.extractRotation(parent->matrixWorld);
		_q1.setFromRotationMatrix(&_m1);
		quaternion->premultiply(_q1.inverse());

	}

};

static void
Object3D_dealloc(Object3D *self)
{

	self->des->call(nullptr);
	delete self->des;
#ifdef  VULKAN_THREE

#ifndef AEOLUS
	 if (self->gubo.buffer != nullptr) { self->gubo.buffer->dealloc(); delete self->gubo.buffer; }
	 for ( auto &u : self->lubo) {
		     u.buffer->dealloc();
			 delete u.buffer;

	 }
#endif


	 if (self->material != nullptr) {
		 Py_DECREF(self->material);
	 }
	 ///Log_o3d("Deriv Object Cast  intensity  %.8Lf    \n", ((Light*)value)->intensity);
	 __Decrement__(self->deriv);

#endif
	Log_o3d("\ndealloc object3D 2\n");
	if (self->position !=NULL) Py_DECREF((PyObject*)self->position);
	if (self->rotation != NULL) Py_DECREF((PyObject*)self->rotation);
	if (self->quaternion != NULL) Py_DECREF((PyObject*)self->quaternion);
	if (self->matrix != NULL) Py_DECREF((PyObject*)self->matrix);
	if (self->matrixWorld != NULL) Py_DECREF((PyObject*)self->matrixWorld);
	if (self->modelViewMatrix != NULL) Py_DECREF((PyObject*)self->modelViewMatrix);
	if (self->normalMatrix != NULL) Py_DECREF((PyObject*)self->normalMatrix);
	if (self->color != NULL) Py_DECREF((PyObject*)self->color);
	if (self->draw.transform != NULL) Py_DECREF((PyObject*)(self->draw.transform));

#ifndef VULKAN_THREE
	if (self->geometry->boundingSphere != nullptr)Py_DECREF((PyObject*)self->geometry->boundingSphere);
#endif
	Log_o3d("\ndealloc geometry\n");
	if(self->geometry !=nullptr)delete self->geometry;

	for (int i = 0; i < self->child.size(); i++) {
		Py_DECREF((PyObject*)self->child.at(i));
	}
	Log_o3d("\nfree O3d\n");

    Py_TYPE(self)->tp_free((PyObject *) self);
}


class object3d_cb {
public:
	Object3D* self;
	object3d_cb(Object3D* _self) :self(_self) {};
	void onRotationChange() {
		//Log_o3d("cb position x %Lf \n ", this->self->position->v[0]);
		self->quaternion->setFromEuler(self->rotation, false);
	};
	void onQuaternionChange() {
		//Log_o3d("cb quaternion %d \n", this->self->matrixWorldNeedsUpdate);
		self->rotation->setFromQuaternion(self->quaternion, self->rotation->DefaultOrder, false);
	}
};

void  Object3D::init() {

	calltype = arth::DRAW::DIRECT;
	frustumCulled = true;
	matrixAutoUpdate = true;
	matrixWorldNeedsUpdate = true;
	drawMode = TrianglesDrawMode;
	id = 0;
	material = nullptr;
	geometry = new _BufferGeometry;

	layers.set(0);

	visible = true;
	draw.hide = false;
	draw.needsBuild = true;
	up.set(DefaultUp.x, DefaultUp.y, DefaultUp.z);

	des = new Desty;
	parent = NULL;
	color = NULL;
	deriv = nullptr;
	draw.transform = nullptr;
	draw.before = nullptr;

	memset(&commander, -1, sizeof(commander));


};
static int
Object3D_init(Object3D* self, PyObject* args, PyObject* kwds)
{
	char* str;
	if (!PyArg_ParseTuple(args, "s", &str))return -1;
	
	self->init();

	return 0;

}

static PyObject *
Object3D_new(PyTypeObject *type, PyObject *args, PyObject *kw)
{

    int rc = -1;
    //Log_o3d("<Object3D>  new \n");
    Object3D *self = NULL;
    self = (Object3D *) type->tp_alloc(type, 0);
    if (!self) goto error;
	self->child.resize(0);

   // self->prev     = NULL;
   // self->next     = NULL;

	//memcpy(self->matrixWorld->elements, identity, sizeof(identity));
	//memcpy(self->matrix->elements, identity, sizeof(identity));
	//self->scale->v[0] = self->scale->v[1] = self->scale->v[2] = 1.;

	//self->rotation->cb     = std::bind(&onRotationChange, self);
	//self->quaternion->cb   = std::bind(&onQuaternionChange, self);
	//self->cb();
    //Log_o3d("b print MatrixWorl pos x %Lf y %Lf z %Lf z %Lf\n", self->matrixWorld.elements[0], self->matrixWorld.elements[5], self->matrixWorld.elements[10], self->matrixWorld.elements[15]);

    rc = 0;

error:
    if(rc <0)Py_XDECREF(self);
    return (PyObject *) self;

}

static PyObject *
Object3D_getPosition(Object3D *self, void *closure)
{
  /*
    PyObject *dlist = PyList_New(3);
    for(int i=0;i<3;i++){
        PyList_SetItem(dlist, i, PyFloat_FromFVAL(self->position.v[i]));
    }
    return dlist;
    */
	//Py_INCREF( (PyObject *) self);
    return  (PyObject *)self->position;
}

static int
Object3D_setPosition(Object3D *self, PyObject *vec, void *closure)
{
    /*for (int i=0; i<3; i++) {
         self->position.v[i]  =  PyFloat_AsFVAL(PyList_GetItem(list, i));
    }*/

	Py_INCREF(vec);
	self->position = ((Vector3*)vec);
    return 0;

}


static PyObject *
Object3D_getRotation(Object3D *self, void *closure)
{
    /*
    PyObject *dlist = PyList_New(3);
    for(int i=0;i<3;i++){
        PyList_SetItem(dlist, i, PyFloat_FromFVAL(self->rotation.v[i]));
    }
    return dlist;
    */
    return  (PyObject *)self->rotation;
}


static int
Object3D_setRotation(Object3D *self, PyObject *vec, void *closure)
{
    /*
    for (int i=0; i<3;i++) {
         self->rotation.v[i]  =  PyFloat_AsFVAL(PyList_GetItem(list, i));
    }
    */
	Py_INCREF(vec);
    self->rotation    =  ((Euler *)vec);
    return 0;
}


static PyObject *
Object3D_getQuaternion(Object3D *self, void *closure)
{
    /*
    PyObject *dlist = PyList_New(3);
    for(int i=0;i<4;i++){
        PyList_SetItem(dlist, i, PyFloat_FromFVAL(self->quaternion.v[i]));
    }
    return dlist;
    */
    return  (PyObject *)(self->quaternion);
}

static int
Object3D_setQuaternion(Object3D *self, PyObject *vec, void *closure)
{
    /*
    for (int i=0; i<4;i++) {
         self->quaternion.v[i]  =  PyFloat_AsFVAL(PyList_GetItem(list, i));
    }
    */
	Py_INCREF(vec);
    self->quaternion = ((Quaternion*)vec);
	//self->quaternion.cb();
    return 0;
}


static PyObject *
Object3D_getScale(Object3D *self, void *closure)
{
    /*
    PyObject *dlist = PyList_New(3);
    for(int i=0;i<3;i++){
        PyList_SetItem(dlist, i, PyFloat_FromFVAL(self->scale.v[i]));
    }
    */
    return  (PyObject *)self->scale;
}

static int
Object3D_setScale(Object3D *self, PyObject *vec, void *closure)
{
    /*
    for (int i=0; i<3; i++) {
         self->scale.v[i]  =  PyFloat_AsFVAL(PyList_GetItem(list, i));
    }
    */
	Py_INCREF(vec);
	self->scale = ((Vector3*)vec);

	//Log_o3d("scale %p", self);
	//printVector3("setscale", self->scale->v);
    return 0;
}


static PyObject *
Object3D_getMatrix(Object3D *self, void *closure)
{
    /*
    PyObject *dlist = PyList_New(3);
    for(int i=0;i<3;i++){
        PyList_SetItem(dlist, i, PyFloat_FromFVAL(self->scale.v[i]));
    }
    */
    return  (PyObject *)self->matrix;
}

static int
Object3D_setMatrix(Object3D *self, PyObject *vec, void *closure)
{
    /*
    for (int i=0; i<3; i++) {
         self->scale.v[i]  =  PyFloat_AsFVAL(PyList_GetItem(list, i));
    }
    */
	Py_INCREF(vec);
	 self->matrix = ((Matrix4*)vec);
    
    return 0;
}

static PyObject *
Object3D_getMatrixWorld(Object3D *self, void *closure)
{
    /*
    PyObject *dlist = PyList_New(3);
    for(int i=0;i<3;i++){
        PyList_SetItem(dlist, i, PyFloat_FromFVAL(self->scale.v[i]));
    }
    */
    return  (PyObject *)self->matrixWorld;
}

static int
Object3D_setMatrixWorld(Object3D *self, PyObject *vec, void *closure)
{
    /*
    for (int i=0; i<3; i++) {
         self->scale.v[i]  =  PyFloat_AsFVAL(PyList_GetItem(list, i));
    }
    */
	Py_INCREF(vec);
	self->matrixWorld = ((Matrix4*)vec);
    return 0;
}



static PyObject*
Object3D_getColor(Object3D* self, void* closure)
{

	return  (PyObject*)self->color;
}
 
static int
Object3D_setColor(Object3D* self, PyObject* vec, void* closure)
{

	Py_INCREF(vec);
	self->color = ((Color*)vec);
	return 0;

}



static PyObject*
Object3D_getType(Object3D* self, void* closure)
{
	return  (PyObject*)PyLong_FromLong((long)self->type);
}

static int
Object3D_setType(Object3D* self, PyObject* obj, void* closure)
{
    
	self->type = (arth::Object)PyLong_AsLong(obj);
	if (self->type == arth::Object::InstancedMesh) {
		self->geometry->type = arth::GEOMETRY::INSTANCED;

	}
	else if (self->type == arth::Object::Points) {
		self->geometry->type = arth::GEOMETRY::COMPUTE;
	}
	else if (self->type == arth::Object::Sprite) {

		self->geometry->type = arth::GEOMETRY::SPRITE;

	}
	else if (self->type == arth::Object::Canvas) {

		self->geometry->type = arth::GEOMETRY::SPRITE;

	}
	else if (self->type == arth::Object::OverlayMesh) {

		self->geometry->type = arth::GEOMETRY::FILE | arth::GEOMETRY::OVERLAY_BIT;

	}
	else{
		self->geometry->type = arth::GEOMETRY::BUFFER;
	}


	return 0;
}

static PyObject*
Object3D_getGeomType(Object3D* self, void* closure)
{
	return  (PyObject*)PyLong_FromLong((long)self->geometry->type);
}


static int
Object3D_setGeomType(Object3D* self, PyObject* obj, void* closure)
{

	self->geometry->type = (arth::GEOMETRY)PyLong_AsLong(obj);
	return 0;
}






static PyObject*
Object3D_getId(Object3D* self, void* closure)
{
	return  (PyObject*)PyLong_FromLong((long)self->id);
}

static int
Object3D_setId(Object3D* self, PyObject* obj, void* closure)
{

	self->id = PyLong_AsLong(obj);
	return 0;
}


static PyObject*
Object3D_getModelViewMatrix(Object3D* self, void* closure)
{
	return  (PyObject*)self->modelViewMatrix;
}

static int
Object3D_setModelViewMatrix(Object3D* self, PyObject* vec, void* closure)
{
	Py_INCREF(vec);
	self->modelViewMatrix  = ((Matrix4*)vec);
	return 0;
}


static PyObject*
Object3D_getNormalMatrix(Object3D* self, void* closure)
{
	return  (PyObject*)self->normalMatrix;
}

static int
Object3D_setNormalMatrix(Object3D* self, PyObject* vec, void* closure)
{
	Py_INCREF(vec);
	self->normalMatrix = ((Matrix3*)vec);
	return 0;
}

static PyObject*
Object3D_getMaterial(Object3D* self, void* closure)
{

	return  (PyObject*)self->material;
}

static int
Object3D_setMaterial(Object3D* self, PyObject* vec, void* closure)
{
	Py_INCREF(vec);

	self->material  = (Material*)vec;
	
	

	return 0;
}

static PyObject*
Object3D_getReceiveShadow(Object3D* self, void* closure)
{
	return PyBool_FromLong(long(self->receiveShadow));
};

static int
Object3D_setReceiveShadow(Object3D* self, PyObject* value, void* closure)
{
	self->receiveShadow = (PyLong_AsLong(value) == 0) ? false : true;
	return 0;
};


static PyObject*
Object3D_getCastShadow(Object3D* self, void* closure)
{
	return PyBool_FromLong(long(self->castShadow));
};

static int
Object3D_setCastShadow(Object3D* self, PyObject* value, void* closure)
{
	self->castShadow = (PyLong_AsLong(value) == 0) ? false : true;
	return 0;
};

PyObject*
Object3D_getVISIBLE(Object3D* self, void* closure)
{
	return PyBool_FromLong(long(self->visible));
};

int
Object3D_setVISIBLE(Object3D* self, PyObject* value, void* closure)
{
	self->visible = (PyLong_AsLong(value) == 0) ? false : true;
	return 0;
};

PyObject*
Object3D_getHIDE(Object3D* self, void* closure)
{
	return PyBool_FromLong(long(self->draw.hide));
};

int
Object3D_setHIDE(Object3D* self, PyObject* value, void* closure)
{
	self->draw.hide = (PyLong_AsLong(value) == 0) ? false : true;
	return 0;
};


PyObject*
Object3D_getFrustum(Object3D* self, void* closure)
{
	return PyBool_FromLong(long(self->frustumCulled));
};

int
Object3D_setFrustum(Object3D* self, PyObject* value, void* closure)
{
	self->frustumCulled = (PyLong_AsLong(value) == 0) ? false : true;
	return 0;
};

static int
Object3D_setDeriv(Object3D* self, PyObject* value, void* closure)
{

	Py_INCREF(value);
	///Log_o3d("Deriv Object Cast  intensity  %.8Lf    \n", ((Light*)value)->intensity);
	self->deriv = value;
	return  0;
};


static PyObject*
Object3D_getDeriv(Object3D* self, void* closure)
{
	Py_INCREF(self->deriv);
	return  (PyObject*)(self->deriv);
}


static PyObject*
Object3D_getCtype(Object3D* self, void* closure)
{
	Py_INCREF(self);
	return  (PyObject*)(self);
}

static PyObject*
Object3D_getLocals(Object3D* self, void* closure)
{
	return  (PyObject*)PyLong_FromLong((long)self->locals);
}

static int
Object3D_setLocals(Object3D* self, PyObject* obj, void* closure)
{

	self->locals = PyLong_AsUnsignedLong(obj);

	return 0;
}


PyObject*
Object3D_getNEEDSSUBMIT(Object3D* self, void* closure)
{
	return PyBool_FromLong(long(self->draw.needsSubmit));
};

int
Object3D_setNEEDSSUBMIT(Object3D* self, PyObject* value, void* closure)
{
	self->draw.needsSubmit = (PyLong_AsLong(value) == 0) ? false : true;
	return 0;
};


static PyGetSetDef Object3D_getsetters[] = {
	 {(char*)"frustumCulled", (getter)Object3D_getFrustum,(setter)Object3D_setFrustum,0,0},
	 {(char*)"_material", (getter)Object3D_getMaterial, (setter)Object3D_setMaterial,0,0},
	 {(char*)"id", (getter)Object3D_getId, (setter)Object3D_setId,0,0},
	  {(char*)"locals", (getter)Object3D_getLocals, (setter)Object3D_setLocals,0,0},
    {(char *)"_position", (getter)Object3D_getPosition, (setter)Object3D_setPosition,0,0},
    {(char *)"_rotation", (getter)Object3D_getRotation, (setter)Object3D_setRotation,0,0},
    {(char *)"_quaternion", (getter)Object3D_getQuaternion, (setter)Object3D_setQuaternion,0,0},
    {(char *)"_scale", (getter)Object3D_getScale, (setter)Object3D_setScale,0,0},
    {(char *)"_matrix", (getter)Object3D_getMatrix, (setter)Object3D_setMatrix,0,0},
    {(char *)"_matrixWorld", (getter)Object3D_getMatrixWorld, (setter)Object3D_setMatrixWorld,0,0},
	 {(char*)"_modelViewMatrix", (getter)Object3D_getModelViewMatrix, (setter)Object3D_setModelViewMatrix,0,0},
	  {(char*)"_normalMatrix", (getter)Object3D_getNormalMatrix, (setter)Object3D_setNormalMatrix,0,0},
	 {(char*)"_color", (getter)Object3D_getColor, (setter)Object3D_setColor,0,0},
	{(char*)"_type", (getter)Object3D_getType, (setter)Object3D_setType,0,0},
	{(char*)"geom_type", (getter)Object3D_getGeomType, (setter)Object3D_setGeomType,0,0},
	{(char*)"drawNeedsSubmit", (getter)Object3D_getNEEDSSUBMIT, (setter)Object3D_setNEEDSSUBMIT,0,0},
	{(char*)"receiveShadow", (getter)Object3D_getReceiveShadow, (setter)Object3D_setReceiveShadow,0,0},
	{(char*)"castShadow", (getter)Object3D_getCastShadow, (setter)Object3D_setCastShadow,0,0},
	{(char*)"visible", (getter)Object3D_getVISIBLE,(setter)Object3D_setVISIBLE,0,0},
	{(char*)"hide", (getter)Object3D_getHIDE,(setter)Object3D_setHIDE,0,0},
	{(char*)"_deriv", (getter)Object3D_getDeriv,(setter)Object3D_setDeriv,0,0},
	{(char*)"_", (getter)Object3D_getCtype, 0,0,0},
    {0},
};


static PyObject*
Object3D_add(Object3D* self, PyObject* args)
{

	Py_ssize_t n = PyTuple_Size(args);

	//Log_o3d("list size %d \n", (int)n);

	for (int i = 0; i < n; i++) {

		Object3D* o = (Object3D*)PyTuple_GetItem(args, i);
		o->parent = self;
		o->id = (int)self->child.size();
		self->child.push_back(o);
		Py_INCREF(o);
		//self->buffer.add(o->id);
		//Log_o3d("parent %d  %p    size %d\n", o->id, o->parent,self->child.size());
	}

	//Log_o3d("child add %d  checksum posiiton.x %Lf \n",i,sb->position.v[0]);
	Py_RETURN_NONE;

}



static PyObject*
Object3D_addGeometry(Object3D* self, PyObject* args)
{

	///Py_ssize_t n = PyTuple_Size(args);
	PyObject* O = PyTuple_GetItem(args, 0);

	CarryAttribute* o = (CarryAttribute*)O;

	self->geometry->nums = (int)o->ob_base.ob_refcnt;
	Py_INCREF(o);

	if (self->type == arth::Object::Points) {
		Log_o3d("Add  ComputeShaderGeometry   Count  %d  \n",o->buffer->updateRange.count);
	}
	else {
		Log_o3d("Add  Geometry Size %u  %zd \n", o->buffer->array.structSize, o->buffer->array.memorySize);
	}
	///self->geometry->attributes =  o->buffer;
	self->geometry->attributes = o;
	Log_o3d("Add  Geometry Size refCnt  %zd \n", o->ob_base.ob_refcnt);
	self->geometry->needsUpdate = true;

	Py_RETURN_NONE;

};

static PyObject*
Object3D_addInstance(Object3D* self, PyObject* args)
{
	CarryAttribute* o = (CarryAttribute*)PyTuple_GetItem(args, 0);
	Log_o3d("Add  Instance Size %u  %zd \n", o->buffer->array.structSize, o->buffer->array.memorySize);
	Py_INCREF(o);
	///self->geometry->instance = o->buffer;
	self->geometry->instance = o;
	self->geometry->needsUpdate  = true;
	self->geometry->instance->buffer->id = -1;
	Py_RETURN_NONE;
};

static PyObject*
Object3D_addMaterial(Object3D* self, PyObject* args)
{
	
	self->material = (Material*)PyTuple_GetItem(args, 0);
	Py_INCREF(self->material);

	/*
	Material* mat = (Material*)PyTuple_GetItem(args, 0);

	Py_INCREF(mat);
	
	switch (mat->type) {
	case arth::MATERIAL::RAW:
		break;
	case  arth::MATERIAL::TEXT:
		self->locals =  ((TextMaterial*)mat)->getLocalSize();
		break;
	}
	*/
	Py_RETURN_NONE;
};

static PyObject*
Object3D_addTransform(Object3D* self, PyObject* args)
{
	self->draw.transform = (PyObject*)PyTuple_GetItem(args, 0);
	Py_INCREF(self->draw.transform);
	//printf("Add  Transform   >>>>>>>>>>>>>>>>>.       %zd   \n", self->draw.transform->ob_refcnt);

	Py_RETURN_NONE;
};


static PyObject*
Object3D_addBefore(Object3D* self, PyObject* args)
{
	self->draw.before = (PyObject*)PyTuple_GetItem(args, 0);
	Py_INCREF(self->draw.before);
	//printf("Add  Transform   >>>>>>>>>>>>>>>>>.       %zd   \n", self->draw.transform->ob_refcnt);

	Py_RETURN_NONE;
};


static PyObject*
Object3D_execTransform(Object3D* self, PyObject* args)
{
	PyObject* res = (PyObject*)PyObject_CallFunctionObjArgs(self->draw.transform,self, NULL);
	//printf("Add  Transform   >>>>>>>>>>>>>>>>>   %zd   \n", self->draw.transform->ob_refcnt);
	PyObject_Print(res, stdout, 0);
	Py_RETURN_NONE;
};


static PyObject*
Object3D_addIndex(Object3D* self, PyObject* args)
{

	Py_RETURN_NONE;
};


static PyObject*
Object3D_addBoundingSphere(Object3D* self, PyObject* args)
{

	Py_RETURN_NONE;
};

static PyObject*
Object3D_setCalltype(Object3D* self, PyObject* args)
{

	self->calltype =   (arth::DRAW)PyLong_AsUnsignedLong(args);
	Log_o3d(" set call Type    %u   \n",self->calltype);

	Py_RETURN_NONE;

};



static PyObject *
Object3D_test(Object3D *self, PyObject *arg)
{

	Log_o3d(" test traverse  %d  \n", int(self->child.size()));

	//for (auto child = self->child.begin(); child != self->child.end(); child++) {
	for (int i = 0; i < self->child.size(); i++) {
		///Object3D* o = self->child.at(i);
		//Log_o3d(" %d  %d test traverse  %p   \n",i, o->id,o);
		//bufferProp* b = self->buffer.child[i];
		//Log_o3d(" %d  id  %d    %s   \n", i, b->buffer, b->name.c_str());
	}

	/*
    int n = PyLong_AsLong(arg);

    Object3D *p = self->child;
	int i = 0;

    if(p == NULL) goto END;
  
   
    LOOP:
        //PY_Log_o3d(item);
        //j = p->position.v[0];
        Log_o3d("child print %d  MatrixWorl pos x %Lf y %Lf z %Lf\n",i,p->matrixWorld->elements[12],p->matrixWorld->elements[13],p->matrixWorld->elements[14]);

        p = p->next;

        i++;
        if(p != NULL) goto LOOP;
        //Py_XDECREF(item);

    //Log_o3d("child fin print %d \n",i);
    END:
	*/
    Py_RETURN_NONE;
}


static PyObject*
Object3D_cb(Object3D* self, PyObject* arg)
{

	    self->setCB();

		 //cb.onQuaternionChange();
		 //cb.onRotationChange();
		 Py_RETURN_NONE;
}

void Object3D::setCB() {
	object3d_cb cb = object3d_cb(this);

	rotation->cb = std::bind(&object3d_cb::onRotationChange, cb);
	quaternion->cb = std::bind(&object3d_cb::onQuaternionChange, cb);

	rotation->cb();
	quaternion->cb();
}


void Object3D::updateMatrixWorld(bool force) {


	if (this->matrixAutoUpdate)this->updateMatrix();

	if (this->matrixWorldNeedsUpdate || force) {

		if (this->parent == NULL)
			this->matrixWorld->copy(this->matrix);
		else
			this->matrixWorld->multiplyMatrices(this->parent->matrixWorld, this->matrix);

		this->matrixWorldNeedsUpdate = false;
		//printMatrix4("matrixWorld",this->matrixWorld->elements);

		{
			force = true;
			// update children
			for (int i =0;i< this->child.size();i++) {
				this->child.at(i)->updateMatrixWorld(force);
			}
		}
	}
}

void Object3D::updateWorldMatrix(bool updateParents,bool updateChildren) {


if (updateParents ==  true && parent !=  NULL) {

	parent->updateWorldMatrix(true, false);

}

if (matrixAutoUpdate) updateMatrix();

if (parent == NULL) {
	matrixWorld->copy(matrix);
}
else {
	matrixWorld->multiplyMatrices(parent->matrixWorld, matrix);
}

// update children

if (updateChildren ==  true) {

	for (auto const & _child : this->child) {
		_child->updateWorldMatrix(false, true);
	 }

}

}

void  Object3D::updateMatrix(){

	   // Log_o3d(" matrix4 compose  refcnt  %d   \n ", (int)this->ob_base.ob_refcnt);

        matrix->compose( position, quaternion, scale );

	//	Log_o3d(" matrix4 after compose  refcnt  %d \n", (int)matrix->ob_base.ob_refcnt);

        matrixWorldNeedsUpdate = true;
       //Log_o3d("updateMatrix %Lf \n",this->position.v[0]);
}

void  Object3D::updateMatrix(Sphere* sp) {

	matrix->compose(position, quaternion, scale);
	matrix->extractSphere(sp);

};

Object3D* Object3D::translateOnAxis(Vector3& axis, _FVAL distance) {

	_v1.copy(&axis)->applyQuaternion(quaternion);
	position->add(_v1.multiplyScalar(distance));
	return this;
};

Object3D* Object3D::translateX(_FVAL distance) {

return translateOnAxis(_xAxis, distance);
}

Object3D* Object3D::translateY(_FVAL distance) {

return translateOnAxis(_yAxis, distance);
}

Object3D* Object3D::translateZ(_FVAL distance) {

return translateOnAxis(_zAxis, distance);
}


static PyObject*
Object3D_updateMatrix(Object3D* self, PyObject* arg) {

	self->updateMatrix();
	Py_RETURN_NONE;
};

static PyObject *
Object3D_updateMatrixWorld(Object3D *self, PyObject *arg){
	   
	 //long  _force = PyLong_AsLong(arg);
	
	 int force = 0;
	 PyArg_ParseTuple(arg, "|i", &force);
	 if(force == 2)  if (self->parent != NULL) Py_RETURN_NONE;

      //Log_o3d("Loop  start %Lf   %d \n",self->position->v[0], force);
      self->updateMatrixWorld((bool)force);
      //Log_o3d("Loop  end %Lf \n",self->position->v[0]);

       Py_RETURN_NONE;
}

PyMethodDef Object3D_tp_methods[] = {
	{"add", (PyCFunction)Object3D_add, METH_VARARGS, 0},
	{"setCalltype", (PyCFunction)Object3D_setCalltype, METH_O, 0},
	{"addIndex", (PyCFunction)Object3D_addIndex, METH_O, 0},
	{"addGeometry", (PyCFunction)Object3D_addGeometry, METH_VARARGS, 0},
	{"addMaterial", (PyCFunction)Object3D_addMaterial, METH_VARARGS, 0},
	{"addInstance", (PyCFunction)Object3D_addInstance, METH_VARARGS, 0},
	{"addBefore", (PyCFunction)Object3D_addBefore, METH_VARARGS, 0},
	{"addTransform", (PyCFunction)Object3D_addTransform, METH_VARARGS, 0},
	{"execTransform", (PyCFunction)Object3D_execTransform, METH_VARARGS, 0},
	{"addBoundingSphere", (PyCFunction)Object3D_addBoundingSphere,METH_O, "Copy Sphere"},
	{"test", (PyCFunction)Object3D_test,  METH_O, 0},
    {"updateMatrix",(PyCFunction)Object3D_updateMatrix,  METH_NOARGS, 0},
	{"updateMatrixWorld", (PyCFunction)Object3D_updateMatrixWorld,  METH_VARARGS, 0},
	{"setCb", (PyCFunction)Object3D_cb,  METH_NOARGS, 0},
	{0},
};

PyTypeObject tp_Object3D = []() -> PyTypeObject  {
    PyTypeObject type = {PyVarObject_HEAD_INIT(0, 0)};
    type.tp_name = "cthreepy.Object3D";
    type.tp_doc = "Object3D objects";
    type.tp_basicsize = sizeof(Object3D);
    type.tp_itemsize = 0;
    type.tp_flags = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE;
    type.tp_new = Object3D_new;
    type.tp_init = (initproc)Object3D_init;
	type.tp_methods = Object3D_tp_methods;
    type.tp_dealloc = (destructor) Object3D_dealloc;
    type.tp_getset = Object3D_getsetters;
    return type;
}();

int AddType_Object3D(PyObject *m){

    if (PyType_Ready(&tp_Object3D) < 0)
        return -1;

    Py_XINCREF(&tp_Object3D);
    PyModule_AddObject(m, "Object3D", (PyObject *) &tp_Object3D);
    return 0;
}


Object3D::Object3D() {

	position = new Vector3;
	rotation = new Euler;
	quaternion = new Quaternion;
	scale = new Vector3(1., 1., 1.);

	matrix           = new Matrix4;
	matrixWorld = new Matrix4;
	modelViewMatrix = new Matrix4;
	normalMatrix = new Matrix3;
	parent = NULL; deriv = NULL;
	matrixAutoUpdate = true;
	setCB();

};


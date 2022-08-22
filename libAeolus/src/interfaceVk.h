#pragma once
#include <concepts>

template <class T>
concept alacarte = requires(T c)
{
	typename T::ctxtype;
	typename T::wintype;

};


template <class T>
concept circus_run = requires(T c, typename T::carteType & carte)
{

	typename T::tankType;
	{
		c.enter(carte)
	}
	->std::convertible_to<bool>;

};


template <class T>
concept Interface_desc = requires(T c)
{
	//typename T::Type;
	//typename T::descType;
	requires sizeof(c.id) == 4;

	{c.type}->std::convertible_to<LayoutType>;
	std::same_as<uint32_t, decltype(c.id)>;
	//std::same_as
};


namespace arth {

	enum class IMAGE_SIGNAL : ENUM_TYPE {
		FromFile     = 0x1,
	    NUMS  
	};
	template <> struct is_flag<IMAGE_SIGNAL> : std::true_type {};
}

namespace image {

	template <class T>
	concept $Interface$image = requires(T c, arth::IMAGE_SIGNAL en,std::string name)
	{
		{c.Whack(en,name)};
	};

	template <$Interface$image Img>
	void image_fromfile(Img& img,std::string filename)
	{
		img.Whack(arth::IMAGE_SIGNAL::FromFile,filename,true);
 
	};

};



/*

template <class T>
concept Interface_desc = requires(T c)
{
	 typename T::Type;
	//typename T::descType;
	{c.getType()}->std::convertible_to<LayoutType>;  //->std::same_as<LayoutType>;
	//{c.id}->std::same_as<uint32_t>;

};
*/
#version 460
#extension GL_NV_ray_tracing : require

struct NodeIO_VOR
{
    int offset;
    uint dimensions;
    vec3 coord;
    float w;
    float scale;
    float smoothness;
    float exponent;
    float randomness;
    uint feature;
    uint metric;
};

layout(location = 2) callableDataInNV NodeIO_VOR nio;

float null_flt;
vec2 null_flt2;
vec4 null_flt3;
vec4 null_flt4;
int null_int;
uint INTERPOLATION_NONE;
uint INTERPOLATION_LINEAR;
uint INTERPOLATION_CLOSEST;
uint INTERPOLATION_CUBIC;
uint INTERPOLATION_SMART;
uint INTERPOLATION_NUM_TYPES;
uint IMAGE_DATA_TYPE_FLOAT4;
uint IMAGE_DATA_TYPE_BYTE4;
uint IMAGE_DATA_TYPE_HALF4;
uint IMAGE_DATA_TYPE_FLOAT;
uint IMAGE_DATA_TYPE_BYTE;
uint IMAGE_DATA_TYPE_HALF;
uint IMAGE_DATA_TYPE_USHORT4;
uint IMAGE_DATA_TYPE_USHORT;
uint IMAGE_DATA_NUM_TYPES;
uint IMAGE_ALPHA_UNASSOCIATED;
uint IMAGE_ALPHA_ASSOCIATED;
uint IMAGE_ALPHA_CHANNEL_PACKED;
uint IMAGE_ALPHA_IGNORE;
uint IMAGE_ALPHA_AUTO;
uint IMAGE_ALPHA_NUM_TYPES;
uint EXTENSION_REPEAT;
uint EXTENSION_EXTEND;
uint EXTENSION_CLIP;
uint EXTENSION_NUM_TYPES;

uint hash_uint(uint kx)
{
    uint c = 3735928576u;
    uint b = 3735928576u;
    uint a = 3735928576u;
    a += kx;
    c ^= b;
    c -= ((b << uint(14)) | (b >> uint(18)));
    a ^= c;
    a -= ((c << uint(11)) | (c >> uint(21)));
    b ^= a;
    b -= ((a << uint(25)) | (a >> uint(7)));
    c ^= b;
    c -= ((b << uint(16)) | (b >> uint(16)));
    a ^= c;
    a -= ((c << uint(4)) | (c >> uint(28)));
    b ^= a;
    b -= ((a << uint(14)) | (a >> uint(18)));
    c ^= b;
    c -= ((b << uint(24)) | (b >> uint(8)));
    return c;
}

float hash_uint_to_float(uint kx)
{
    uint param = kx;
    return float(hash_uint(param)) / 4294967296.0;
}

float hash_float_to_float(float k)
{
    uint param = floatBitsToUint(k);
    return hash_uint_to_float(param);
}

float voronoi_distance_1d(float a, float b, uint metric, float exponent)
{
    return abs(b - a);
}

uint hash_uint2(uint kx, uint ky)
{
    uint c = 3735928580u;
    uint b = 3735928580u;
    uint a = 3735928580u;
    b += ky;
    a += kx;
    c ^= b;
    c -= ((b << uint(14)) | (b >> uint(18)));
    a ^= c;
    a -= ((c << uint(11)) | (c >> uint(21)));
    b ^= a;
    b -= ((a << uint(25)) | (a >> uint(7)));
    c ^= b;
    c -= ((b << uint(16)) | (b >> uint(16)));
    a ^= c;
    a -= ((c << uint(4)) | (c >> uint(28)));
    b ^= a;
    b -= ((a << uint(14)) | (a >> uint(18)));
    c ^= b;
    c -= ((b << uint(24)) | (b >> uint(8)));
    return c;
}

float hash_uint2_to_float(uint kx, uint ky)
{
    uint param = kx;
    uint param_1 = ky;
    return float(hash_uint2(param, param_1)) / 4294967296.0;
}

float hash_float2_to_float(vec2 k)
{
    uint param = floatBitsToUint(k.x);
    uint param_1 = floatBitsToUint(k.y);
    return hash_uint2_to_float(param, param_1);
}

vec4 hash_float_to_float3(float k)
{
    float param = k;
    vec2 param_1 = vec2(k, 1.0);
    vec2 param_2 = vec2(k, 2.0);
    return vec4(hash_float_to_float(param), hash_float2_to_float(param_1), hash_float2_to_float(param_2), 0.0);
}

void voronoi_f1_1d(float w, float exponent, float randomness, uint metric, inout float outDistance, inout vec4 outColor, inout float outW)
{
    float cellPosition = floor(w);
    float localPosition = w - cellPosition;
    float minDistance = 8.0;
    float targetOffset = 0.0;
    float targetPosition = 0.0;
    for (int i = -1; i <= 1; i++)
    {
        float cellOffset = float(i);
        float param = cellPosition + cellOffset;
        float pointPosition = cellOffset + (hash_float_to_float(param) * randomness);
        float param_1 = pointPosition;
        float param_2 = localPosition;
        uint param_3 = metric;
        float param_4 = exponent;
        float distanceToPoint = voronoi_distance_1d(param_1, param_2, param_3, param_4);
        if (distanceToPoint < minDistance)
        {
            targetOffset = cellOffset;
            minDistance = distanceToPoint;
            targetPosition = pointPosition;
        }
    }
    outDistance = minDistance;
    float param_5 = cellPosition + targetOffset;
    outColor = hash_float_to_float3(param_5);
    outW = targetPosition + cellPosition;
}

void voronoi_smooth_f1_1d(float w, float smoothness, float exponent, float randomness, uint metric, inout float outDistance, inout vec4 outColor, inout float outW)
{
    float cellPosition = floor(w);
    float localPosition = w - cellPosition;
    float smoothDistance = 8.0;
    float smoothPosition = 0.0;
    vec4 smoothColor = vec4(0.0);
    for (int i = -2; i <= 2; i++)
    {
        float cellOffset = float(i);
        float param = cellPosition + cellOffset;
        float pointPosition = cellOffset + (hash_float_to_float(param) * randomness);
        float param_1 = pointPosition;
        float param_2 = localPosition;
        uint param_3 = metric;
        float param_4 = exponent;
        float distanceToPoint = voronoi_distance_1d(param_1, param_2, param_3, param_4);
        float h = smoothstep(0.0, 1.0, 0.5 + ((0.5 * (smoothDistance - distanceToPoint)) / smoothness));
        float correctionFactor = (smoothness * h) * (1.0 - h);
        smoothDistance = mix(smoothDistance, distanceToPoint, h) - correctionFactor;
        correctionFactor /= (1.0 + (3.0 * smoothness));
        float param_5 = cellPosition + cellOffset;
        vec4 cellColor = hash_float_to_float3(param_5);
        smoothColor = mix(smoothColor, cellColor, vec4(h)) - vec4(correctionFactor);
        smoothPosition = mix(smoothPosition, pointPosition, h) - correctionFactor;
    }
    outDistance = smoothDistance;
    outColor = smoothColor;
    outW = cellPosition + smoothPosition;
}

void voronoi_f2_1d(float w, float exponent, float randomness, uint metric, inout float outDistance, inout vec4 outColor, inout float outW)
{
    float cellPosition = floor(w);
    float localPosition = w - cellPosition;
    float distanceF1 = 8.0;
    float distanceF2 = 8.0;
    float offsetF1 = 0.0;
    float positionF1 = 0.0;
    float offsetF2 = 0.0;
    float positionF2 = 0.0;
    for (int i = -1; i <= 1; i++)
    {
        float cellOffset = float(i);
        float param = cellPosition + cellOffset;
        float pointPosition = cellOffset + (hash_float_to_float(param) * randomness);
        float param_1 = pointPosition;
        float param_2 = localPosition;
        uint param_3 = metric;
        float param_4 = exponent;
        float distanceToPoint = voronoi_distance_1d(param_1, param_2, param_3, param_4);
        if (distanceToPoint < distanceF1)
        {
            distanceF2 = distanceF1;
            distanceF1 = distanceToPoint;
            offsetF2 = offsetF1;
            offsetF1 = cellOffset;
            positionF2 = positionF1;
            positionF1 = pointPosition;
        }
        else
        {
            if (distanceToPoint < distanceF2)
            {
                distanceF2 = distanceToPoint;
                offsetF2 = cellOffset;
                positionF2 = pointPosition;
            }
        }
    }
    outDistance = distanceF2;
    float param_5 = cellPosition + offsetF2;
    outColor = hash_float_to_float3(param_5);
    outW = positionF2 + cellPosition;
}

void voronoi_distance_to_edge_1d(float w, float randomness, inout float outDistance)
{
    float cellPosition = floor(w);
    float localPosition = w - cellPosition;
    float minDistance = 8.0;
    for (int i = -1; i <= 1; i++)
    {
        float cellOffset = float(i);
        float param = cellPosition + cellOffset;
        float pointPosition = cellOffset + (hash_float_to_float(param) * randomness);
        float distanceToPoint = abs(pointPosition - localPosition);
        minDistance = min(distanceToPoint, minDistance);
    }
    outDistance = minDistance;
}

void voronoi_n_sphere_radius_1d(float w, float randomness, inout float outRadius)
{
    float cellPosition = floor(w);
    float localPosition = w - cellPosition;
    float closestPoint = 0.0;
    float closestPointOffset = 0.0;
    float minDistance = 8.0;
    for (int i = -1; i <= 1; i++)
    {
        float cellOffset = float(i);
        float param = cellPosition + cellOffset;
        float pointPosition = cellOffset + (hash_float_to_float(param) * randomness);
        float distanceToPoint = abs(pointPosition - localPosition);
        if (distanceToPoint < minDistance)
        {
            minDistance = distanceToPoint;
            closestPoint = pointPosition;
            closestPointOffset = cellOffset;
        }
    }
    minDistance = 8.0;
    float closestPointToClosestPoint = 0.0;
    for (int i_1 = -1; i_1 <= 1; i_1++)
    {
        if (i_1 == 0)
        {
            continue;
        }
        float cellOffset_1 = float(i_1) + closestPointOffset;
        float param_1 = cellPosition + cellOffset_1;
        float pointPosition_1 = cellOffset_1 + (hash_float_to_float(param_1) * randomness);
        float distanceToPoint_1 = abs(closestPoint - pointPosition_1);
        if (distanceToPoint_1 < minDistance)
        {
            minDistance = distanceToPoint_1;
            closestPointToClosestPoint = pointPosition_1;
        }
    }
    outRadius = abs(closestPointToClosestPoint - closestPoint) / 2.0;
}

float safe_divide(float a, float b)
{
    float _390;
    if (!(b == 0.0))
    {
        _390 = a / b;
    }
    else
    {
        _390 = 0.0;
    }
    return _390;
}

uint hash_uint3(uint kx, uint ky, uint kz)
{
    uint c = 3735928584u;
    uint b = 3735928584u;
    uint a = 3735928584u;
    c += kz;
    b += ky;
    a += kx;
    c ^= b;
    c -= ((b << uint(14)) | (b >> uint(18)));
    a ^= c;
    a -= ((c << uint(11)) | (c >> uint(21)));
    b ^= a;
    b -= ((a << uint(25)) | (a >> uint(7)));
    c ^= b;
    c -= ((b << uint(16)) | (b >> uint(16)));
    a ^= c;
    a -= ((c << uint(4)) | (c >> uint(28)));
    b ^= a;
    b -= ((a << uint(14)) | (a >> uint(18)));
    c ^= b;
    c -= ((b << uint(24)) | (b >> uint(8)));
    return c;
}

float hash_uint3_to_float(uint kx, uint ky, uint kz)
{
    uint param = kx;
    uint param_1 = ky;
    uint param_2 = kz;
    return float(hash_uint3(param, param_1, param_2)) / 4294967296.0;
}

float hash_float3_to_float(vec4 k)
{
    uint param = floatBitsToUint(k.x);
    uint param_1 = floatBitsToUint(k.y);
    uint param_2 = floatBitsToUint(k.z);
    return hash_uint3_to_float(param, param_1, param_2);
}

vec2 hash_float2_to_float2(vec2 k)
{
    vec2 param = k;
    vec4 param_1 = vec4(k.x, k.y, 1.0, 0.0);
    return vec2(hash_float2_to_float(param), hash_float3_to_float(param_1));
}

float voronoi_distance_2d(vec2 a, vec2 b, uint metric, float exponent)
{
    if (metric == 0u)
    {
        return distance(a, b);
    }
    else
    {
        if (metric == 1u)
        {
            return abs(a.x - b.x) + abs(a.y - b.y);
        }
        else
        {
            if (metric == 2u)
            {
                return max(abs(a.x - b.x), abs(a.y - b.y));
            }
            else
            {
                if (metric == 3u)
                {
                    return pow(pow(abs(a.x - b.x), exponent) + pow(abs(a.y - b.y), exponent), 1.0 / exponent);
                }
                else
                {
                    return 0.0;
                }
            }
        }
    }
}

vec4 hash_float2_to_float3(vec2 k)
{
    vec2 param = k;
    vec4 param_1 = vec4(k.x, k.y, 1.0, 0.0);
    vec4 param_2 = vec4(k.x, k.y, 2.0, 0.0);
    return vec4(hash_float2_to_float(param), hash_float3_to_float(param_1), hash_float3_to_float(param_2), 0.0);
}

void voronoi_f1_2d(vec2 coord, float exponent, float randomness, uint metric, inout float outDistance, inout vec4 outColor, inout vec2 outPosition)
{
    vec2 cellPosition = floor(coord);
    vec2 localPosition = coord - cellPosition;
    float minDistance = 8.0;
    vec2 targetOffset = vec2(0.0);
    vec2 targetPosition = vec2(0.0);
    for (int j = -1; j <= 1; j++)
    {
        for (int i = -1; i <= 1; i++)
        {
            vec2 cellOffset = vec2(float(i), float(j));
            vec2 param = cellPosition + cellOffset;
            vec2 pointPosition = cellOffset + (hash_float2_to_float2(param) * randomness);
            vec2 param_1 = pointPosition;
            vec2 param_2 = localPosition;
            uint param_3 = metric;
            float param_4 = exponent;
            float distanceToPoint = voronoi_distance_2d(param_1, param_2, param_3, param_4);
            if (distanceToPoint < minDistance)
            {
                targetOffset = cellOffset;
                minDistance = distanceToPoint;
                targetPosition = pointPosition;
            }
        }
    }
    outDistance = minDistance;
    vec2 param_5 = cellPosition + targetOffset;
    outColor = hash_float2_to_float3(param_5);
    outPosition = targetPosition + cellPosition;
}

void voronoi_smooth_f1_2d(vec2 coord, float smoothness, float exponent, float randomness, uint metric, inout float outDistance, inout vec4 outColor, inout vec2 outPosition)
{
    vec2 cellPosition = floor(coord);
    vec2 localPosition = coord - cellPosition;
    float smoothDistance = 8.0;
    vec4 smoothColor = vec4(0.0);
    vec2 smoothPosition = vec2(0.0);
    for (int j = -2; j <= 2; j++)
    {
        for (int i = -2; i <= 2; i++)
        {
            vec2 cellOffset = vec2(float(i), float(j));
            vec2 param = cellPosition + cellOffset;
            vec2 pointPosition = cellOffset + (hash_float2_to_float2(param) * randomness);
            vec2 param_1 = pointPosition;
            vec2 param_2 = localPosition;
            uint param_3 = metric;
            float param_4 = exponent;
            float distanceToPoint = voronoi_distance_2d(param_1, param_2, param_3, param_4);
            float h = smoothstep(0.0, 1.0, 0.5 + ((0.5 * (smoothDistance - distanceToPoint)) / smoothness));
            float correctionFactor = (smoothness * h) * (1.0 - h);
            smoothDistance = mix(smoothDistance, distanceToPoint, h) - correctionFactor;
            correctionFactor /= (1.0 + (3.0 * smoothness));
            vec2 param_5 = cellPosition + cellOffset;
            vec4 cellColor = hash_float2_to_float3(param_5);
            smoothColor = mix(smoothColor, cellColor, vec4(h)) - vec4(correctionFactor);
            smoothPosition = mix(smoothPosition, pointPosition, vec2(h)) - vec2(correctionFactor);
        }
    }
    outDistance = smoothDistance;
    outColor = smoothColor;
    outPosition = cellPosition + smoothPosition;
}

void voronoi_f2_2d(vec2 coord, float exponent, float randomness, uint metric, inout float outDistance, inout vec4 outColor, inout vec2 outPosition)
{
    vec2 cellPosition = floor(coord);
    vec2 localPosition = coord - cellPosition;
    float distanceF1 = 8.0;
    float distanceF2 = 8.0;
    vec2 offsetF1 = vec2(0.0);
    vec2 positionF1 = vec2(0.0);
    vec2 offsetF2 = vec2(0.0);
    vec2 positionF2 = vec2(0.0);
    for (int j = -1; j <= 1; j++)
    {
        for (int i = -1; i <= 1; i++)
        {
            vec2 cellOffset = vec2(float(i), float(j));
            vec2 param = cellPosition + cellOffset;
            vec2 pointPosition = cellOffset + (hash_float2_to_float2(param) * randomness);
            vec2 param_1 = pointPosition;
            vec2 param_2 = localPosition;
            uint param_3 = metric;
            float param_4 = exponent;
            float distanceToPoint = voronoi_distance_2d(param_1, param_2, param_3, param_4);
            if (distanceToPoint < distanceF1)
            {
                distanceF2 = distanceF1;
                distanceF1 = distanceToPoint;
                offsetF2 = offsetF1;
                offsetF1 = cellOffset;
                positionF2 = positionF1;
                positionF1 = pointPosition;
            }
            else
            {
                if (distanceToPoint < distanceF2)
                {
                    distanceF2 = distanceToPoint;
                    offsetF2 = cellOffset;
                    positionF2 = pointPosition;
                }
            }
        }
    }
    outDistance = distanceF2;
    vec2 param_5 = cellPosition + offsetF2;
    outColor = hash_float2_to_float3(param_5);
    outPosition = positionF2 + cellPosition;
}

void voronoi_distance_to_edge_2d(vec2 coord, float randomness, inout float outDistance)
{
    vec2 cellPosition = floor(coord);
    vec2 localPosition = coord - cellPosition;
    vec2 vectorToClosest = vec2(0.0);
    float minDistance = 8.0;
    for (int j = -1; j <= 1; j++)
    {
        for (int i = -1; i <= 1; i++)
        {
            vec2 cellOffset = vec2(float(i), float(j));
            vec2 param = cellPosition + cellOffset;
            vec2 vectorToPoint = (cellOffset + (hash_float2_to_float2(param) * randomness)) - localPosition;
            float distanceToPoint = dot(vectorToPoint, vectorToPoint);
            if (distanceToPoint < minDistance)
            {
                minDistance = distanceToPoint;
                vectorToClosest = vectorToPoint;
            }
        }
    }
    minDistance = 8.0;
    for (int j_1 = -1; j_1 <= 1; j_1++)
    {
        for (int i_1 = -1; i_1 <= 1; i_1++)
        {
            vec2 cellOffset_1 = vec2(float(i_1), float(j_1));
            vec2 param_1 = cellPosition + cellOffset_1;
            vec2 vectorToPoint_1 = (cellOffset_1 + (hash_float2_to_float2(param_1) * randomness)) - localPosition;
            vec2 perpendicularToEdge = vectorToPoint_1 - vectorToClosest;
            if (dot(perpendicularToEdge, perpendicularToEdge) > 9.9999997473787516355514526367188e-05)
            {
                float distanceToEdge = dot((vectorToClosest + vectorToPoint_1) / vec2(2.0), normalize(perpendicularToEdge));
                minDistance = min(minDistance, distanceToEdge);
            }
        }
    }
    outDistance = minDistance;
}

void voronoi_n_sphere_radius_2d(vec2 coord, float randomness, inout float outRadius)
{
    vec2 cellPosition = floor(coord);
    vec2 localPosition = coord - cellPosition;
    vec2 closestPoint = vec2(0.0);
    vec2 closestPointOffset = vec2(0.0);
    float minDistance = 8.0;
    for (int j = -1; j <= 1; j++)
    {
        for (int i = -1; i <= 1; i++)
        {
            vec2 cellOffset = vec2(float(i), float(j));
            vec2 param = cellPosition + cellOffset;
            vec2 pointPosition = cellOffset + (hash_float2_to_float2(param) * randomness);
            float distanceToPoint = distance(pointPosition, localPosition);
            if (distanceToPoint < minDistance)
            {
                minDistance = distanceToPoint;
                closestPoint = pointPosition;
                closestPointOffset = cellOffset;
            }
        }
    }
    minDistance = 8.0;
    vec2 closestPointToClosestPoint = vec2(0.0);
    for (int j_1 = -1; j_1 <= 1; j_1++)
    {
        for (int i_1 = -1; i_1 <= 1; i_1++)
        {
            if ((i_1 == 0) && (j_1 == 0))
            {
                continue;
            }
            vec2 cellOffset_1 = vec2(float(i_1), float(j_1)) + closestPointOffset;
            vec2 param_1 = cellPosition + cellOffset_1;
            vec2 pointPosition_1 = cellOffset_1 + (hash_float2_to_float2(param_1) * randomness);
            float distanceToPoint_1 = distance(closestPoint, pointPosition_1);
            if (distanceToPoint_1 < minDistance)
            {
                minDistance = distanceToPoint_1;
                closestPointToClosestPoint = pointPosition_1;
            }
        }
    }
    outRadius = distance(closestPointToClosestPoint, closestPoint) / 2.0;
}

vec2 safe_divide_float2_float(vec2 a, float b)
{
    vec2 _357;
    if (!(b == 0.0))
    {
        _357 = a / vec2(b);
    }
    else
    {
        _357 = vec2(0.0);
    }
    return _357;
}

uint hash_uint4(uint kx, uint ky, uint kz, uint kw)
{
    uint c = 3735928588u;
    uint b = 3735928588u;
    uint a = 3735928588u;
    a += kx;
    b += ky;
    c += kz;
    a -= c;
    a ^= ((c << uint(4)) | (c >> uint(28)));
    c += b;
    b -= a;
    b ^= ((a << uint(6)) | (a >> uint(26)));
    a += c;
    c -= b;
    c ^= ((b << uint(8)) | (b >> uint(24)));
    b += a;
    a -= c;
    a ^= ((c << uint(16)) | (c >> uint(16)));
    c += b;
    b -= a;
    b ^= ((a << uint(19)) | (a >> uint(13)));
    a += c;
    c -= b;
    c ^= ((b << uint(4)) | (b >> uint(28)));
    b += a;
    a += kw;
    c ^= b;
    c -= ((b << uint(14)) | (b >> uint(18)));
    a ^= c;
    a -= ((c << uint(11)) | (c >> uint(21)));
    b ^= a;
    b -= ((a << uint(25)) | (a >> uint(7)));
    c ^= b;
    c -= ((b << uint(16)) | (b >> uint(16)));
    a ^= c;
    a -= ((c << uint(4)) | (c >> uint(28)));
    b ^= a;
    b -= ((a << uint(14)) | (a >> uint(18)));
    c ^= b;
    c -= ((b << uint(24)) | (b >> uint(8)));
    return c;
}

float hash_uint4_to_float(uint kx, uint ky, uint kz, uint kw)
{
    uint param = kx;
    uint param_1 = ky;
    uint param_2 = kz;
    uint param_3 = kw;
    return float(hash_uint4(param, param_1, param_2, param_3)) / 4294967296.0;
}

float hash_float4_to_float(vec4 k)
{
    uint param = floatBitsToUint(k.x);
    uint param_1 = floatBitsToUint(k.y);
    uint param_2 = floatBitsToUint(k.z);
    uint param_3 = floatBitsToUint(k.w);
    return hash_uint4_to_float(param, param_1, param_2, param_3);
}

vec4 hash_float3_to_float3(vec4 k)
{
    vec4 param = k;
    vec4 param_1 = vec4(k.x, k.y, k.z, 1.0);
    vec4 param_2 = vec4(k.x, k.y, k.z, 2.0);
    return vec4(hash_float3_to_float(param), hash_float4_to_float(param_1), hash_float4_to_float(param_2), 0.0);
}

float voronoi_distance_3d(vec4 a, vec4 b, uint metric, float exponent)
{
    if (metric == 0u)
    {
        return distance(a, b);
    }
    else
    {
        if (metric == 1u)
        {
            return (abs(a.x - b.x) + abs(a.y - b.y)) + abs(a.z - b.z);
        }
        else
        {
            if (metric == 2u)
            {
                return max(abs(a.x - b.x), max(abs(a.y - b.y), abs(a.z - b.z)));
            }
            else
            {
                if (metric == 3u)
                {
                    return pow((pow(abs(a.x - b.x), exponent) + pow(abs(a.y - b.y), exponent)) + pow(abs(a.z - b.z), exponent), 1.0 / exponent);
                }
                else
                {
                    return 0.0;
                }
            }
        }
    }
}

void voronoi_f1_3d(vec4 coord, float exponent, float randomness, uint metric, inout float outDistance, inout vec4 outColor, inout vec4 outPosition)
{
    vec4 cellPosition = floor(coord);
    vec4 localPosition = coord - cellPosition;
    float minDistance = 8.0;
    vec4 targetOffset = vec4(0.0);
    vec4 targetPosition = vec4(0.0);
    for (int k = -1; k <= 1; k++)
    {
        for (int j = -1; j <= 1; j++)
        {
            for (int i = -1; i <= 1; i++)
            {
                vec4 cellOffset = vec4(float(i), float(j), float(k), 0.0);
                vec4 param = cellPosition + cellOffset;
                vec4 pointPosition = cellOffset + (hash_float3_to_float3(param) * randomness);
                vec4 param_1 = pointPosition;
                vec4 param_2 = localPosition;
                uint param_3 = metric;
                float param_4 = exponent;
                float distanceToPoint = voronoi_distance_3d(param_1, param_2, param_3, param_4);
                if (distanceToPoint < minDistance)
                {
                    targetOffset = cellOffset;
                    minDistance = distanceToPoint;
                    targetPosition = pointPosition;
                }
            }
        }
    }
    outDistance = minDistance;
    vec4 param_5 = cellPosition + targetOffset;
    outColor = hash_float3_to_float3(param_5);
    outPosition = targetPosition + cellPosition;
}

void voronoi_smooth_f1_3d(vec4 coord, float smoothness, float exponent, float randomness, uint metric, inout float outDistance, inout vec4 outColor, inout vec4 outPosition)
{
    vec4 cellPosition = floor(coord);
    vec4 localPosition = coord - cellPosition;
    float smoothDistance = 8.0;
    vec4 smoothColor = vec4(0.0);
    vec4 smoothPosition = vec4(0.0);
    for (int k = -2; k <= 2; k++)
    {
        for (int j = -2; j <= 2; j++)
        {
            for (int i = -2; i <= 2; i++)
            {
                vec4 cellOffset = vec4(float(i), float(j), float(k), 0.0);
                vec4 param = cellPosition + cellOffset;
                vec4 pointPosition = cellOffset + (hash_float3_to_float3(param) * randomness);
                vec4 param_1 = pointPosition;
                vec4 param_2 = localPosition;
                uint param_3 = metric;
                float param_4 = exponent;
                float distanceToPoint = voronoi_distance_3d(param_1, param_2, param_3, param_4);
                float h = smoothstep(0.0, 1.0, 0.5 + ((0.5 * (smoothDistance - distanceToPoint)) / smoothness));
                float correctionFactor = (smoothness * h) * (1.0 - h);
                smoothDistance = mix(smoothDistance, distanceToPoint, h) - correctionFactor;
                correctionFactor /= (1.0 + (3.0 * smoothness));
                vec4 param_5 = cellPosition + cellOffset;
                vec4 cellColor = hash_float3_to_float3(param_5);
                smoothColor = mix(smoothColor, cellColor, vec4(h)) - vec4(correctionFactor);
                smoothPosition = mix(smoothPosition, pointPosition, vec4(h)) - vec4(correctionFactor);
            }
        }
    }
    outDistance = smoothDistance;
    outColor = smoothColor;
    outPosition = cellPosition + smoothPosition;
}

void voronoi_f2_3d(vec4 coord, float exponent, float randomness, uint metric, inout float outDistance, inout vec4 outColor, inout vec4 outPosition)
{
    vec4 cellPosition = floor(coord);
    vec4 localPosition = coord - cellPosition;
    float distanceF1 = 8.0;
    float distanceF2 = 8.0;
    vec4 offsetF1 = vec4(0.0);
    vec4 positionF1 = vec4(0.0);
    vec4 offsetF2 = vec4(0.0);
    vec4 positionF2 = vec4(0.0);
    for (int k = -1; k <= 1; k++)
    {
        for (int j = -1; j <= 1; j++)
        {
            for (int i = -1; i <= 1; i++)
            {
                vec4 cellOffset = vec4(float(i), float(j), float(k), 0.0);
                vec4 param = cellPosition + cellOffset;
                vec4 pointPosition = cellOffset + (hash_float3_to_float3(param) * randomness);
                vec4 param_1 = pointPosition;
                vec4 param_2 = localPosition;
                uint param_3 = metric;
                float param_4 = exponent;
                float distanceToPoint = voronoi_distance_3d(param_1, param_2, param_3, param_4);
                if (distanceToPoint < distanceF1)
                {
                    distanceF2 = distanceF1;
                    distanceF1 = distanceToPoint;
                    offsetF2 = offsetF1;
                    offsetF1 = cellOffset;
                    positionF2 = positionF1;
                    positionF1 = pointPosition;
                }
                else
                {
                    if (distanceToPoint < distanceF2)
                    {
                        distanceF2 = distanceToPoint;
                        offsetF2 = cellOffset;
                        positionF2 = pointPosition;
                    }
                }
            }
        }
    }
    outDistance = distanceF2;
    vec4 param_5 = cellPosition + offsetF2;
    outColor = hash_float3_to_float3(param_5);
    outPosition = positionF2 + cellPosition;
}

void voronoi_distance_to_edge_3d(vec4 coord, float randomness, inout float outDistance)
{
    vec4 cellPosition = floor(coord);
    vec4 localPosition = coord - cellPosition;
    vec4 vectorToClosest = vec4(0.0);
    float minDistance = 8.0;
    for (int k = -1; k <= 1; k++)
    {
        for (int j = -1; j <= 1; j++)
        {
            for (int i = -1; i <= 1; i++)
            {
                vec4 cellOffset = vec4(float(i), float(j), float(k), 0.0);
                vec4 param = cellPosition + cellOffset;
                vec4 vectorToPoint = (cellOffset + (hash_float3_to_float3(param) * randomness)) - localPosition;
                float distanceToPoint = dot(vectorToPoint.xyz, vectorToPoint.xyz);
                if (distanceToPoint < minDistance)
                {
                    minDistance = distanceToPoint;
                    vectorToClosest = vectorToPoint;
                }
            }
        }
    }
    minDistance = 8.0;
    for (int k_1 = -1; k_1 <= 1; k_1++)
    {
        for (int j_1 = -1; j_1 <= 1; j_1++)
        {
            for (int i_1 = -1; i_1 <= 1; i_1++)
            {
                vec4 cellOffset_1 = vec4(float(i_1), float(j_1), float(k_1), 0.0);
                vec4 param_1 = cellPosition + cellOffset_1;
                vec4 vectorToPoint_1 = (cellOffset_1 + (hash_float3_to_float3(param_1) * randomness)) - localPosition;
                vec4 perpendicularToEdge = vectorToPoint_1 - vectorToClosest;
                if (dot(perpendicularToEdge.xyz, perpendicularToEdge.xyz) > 9.9999997473787516355514526367188e-05)
                {
                    float distanceToEdge = dot(((vectorToClosest + vectorToPoint_1) / vec4(2.0)).xyz, normalize(perpendicularToEdge).xyz);
                    minDistance = min(minDistance, distanceToEdge);
                }
            }
        }
    }
    outDistance = minDistance;
}

void voronoi_n_sphere_radius_3d(vec4 coord, float randomness, inout float outRadius)
{
    vec4 cellPosition = floor(coord);
    vec4 localPosition = coord - cellPosition;
    vec4 closestPoint = vec4(0.0);
    vec4 closestPointOffset = vec4(0.0);
    float minDistance = 8.0;
    for (int k = -1; k <= 1; k++)
    {
        for (int j = -1; j <= 1; j++)
        {
            for (int i = -1; i <= 1; i++)
            {
                vec4 cellOffset = vec4(float(i), float(j), float(k), 0.0);
                vec4 param = cellPosition + cellOffset;
                vec4 pointPosition = cellOffset + (hash_float3_to_float3(param) * randomness);
                float distanceToPoint = distance(pointPosition, localPosition);
                if (distanceToPoint < minDistance)
                {
                    minDistance = distanceToPoint;
                    closestPoint = pointPosition;
                    closestPointOffset = cellOffset;
                }
            }
        }
    }
    minDistance = 8.0;
    vec4 closestPointToClosestPoint = vec4(0.0);
    for (int k_1 = -1; k_1 <= 1; k_1++)
    {
        for (int j_1 = -1; j_1 <= 1; j_1++)
        {
            for (int i_1 = -1; i_1 <= 1; i_1++)
            {
                if (((i_1 == 0) && (j_1 == 0)) && (k_1 == 0))
                {
                    continue;
                }
                vec4 cellOffset_1 = vec4(float(i_1), float(j_1), float(k_1), 0.0) + closestPointOffset;
                vec4 param_1 = cellPosition + cellOffset_1;
                vec4 pointPosition_1 = cellOffset_1 + (hash_float3_to_float3(param_1) * randomness);
                float distanceToPoint_1 = distance(closestPoint, pointPosition_1);
                if (distanceToPoint_1 < minDistance)
                {
                    minDistance = distanceToPoint_1;
                    closestPointToClosestPoint = pointPosition_1;
                }
            }
        }
    }
    outRadius = distance(closestPointToClosestPoint, closestPoint) / 2.0;
}

vec4 safe_divide_float3_float(vec4 a, float b)
{
    vec4 _368;
    if (!(b == 0.0))
    {
        _368 = a / vec4(b);
    }
    else
    {
        _368 = vec4(0.0);
    }
    return _368;
}

vec4 hash_float4_to_float4(vec4 k)
{
    vec4 param = k;
    vec4 param_1 = vec4(k.w, k.x, k.y, k.z);
    vec4 param_2 = vec4(k.z, k.w, k.x, k.y);
    vec4 param_3 = vec4(k.y, k.z, k.w, k.x);
    return vec4(hash_float4_to_float(param), hash_float4_to_float(param_1), hash_float4_to_float(param_2), hash_float4_to_float(param_3));
}

float voronoi_distance_4d(vec4 a, vec4 b, uint metric, float exponent)
{
    if (metric == 0u)
    {
        return distance(a, b);
    }
    else
    {
        if (metric == 1u)
        {
            return ((abs(a.x - b.x) + abs(a.y - b.y)) + abs(a.z - b.z)) + abs(a.w - b.w);
        }
        else
        {
            if (metric == 2u)
            {
                return max(abs(a.x - b.x), max(abs(a.y - b.y), max(abs(a.z - b.z), abs(a.w - b.w))));
            }
            else
            {
                if (metric == 3u)
                {
                    return pow(((pow(abs(a.x - b.x), exponent) + pow(abs(a.y - b.y), exponent)) + pow(abs(a.z - b.z), exponent)) + pow(abs(a.w - b.w), exponent), 1.0 / exponent);
                }
                else
                {
                    return 0.0;
                }
            }
        }
    }
}

vec4 hash_float4_to_float3(vec4 k)
{
    vec4 param = k;
    vec4 param_1 = vec4(k.z, k.x, k.w, k.y);
    vec4 param_2 = vec4(k.w, k.z, k.y, k.x);
    return vec4(hash_float4_to_float(param), hash_float4_to_float(param_1), hash_float4_to_float(param_2), 0.0);
}

void voronoi_f1_4d(vec4 coord, float exponent, float randomness, uint metric, inout float outDistance, inout vec4 outColor, inout vec4 outPosition)
{
    vec4 cellPosition = floor(coord);
    vec4 localPosition = coord - cellPosition;
    float minDistance = 8.0;
    vec4 targetOffset = vec4(0.0);
    vec4 targetPosition = vec4(0.0);
    for (int u = -1; u <= 1; u++)
    {
        for (int k = -1; k <= 1; k++)
        {
            for (int j = -1; j <= 1; j++)
            {
                for (int i = -1; i <= 1; i++)
                {
                    vec4 cellOffset = vec4(float(i), float(j), float(k), float(u));
                    vec4 param = cellPosition + cellOffset;
                    vec4 pointPosition = cellOffset + (hash_float4_to_float4(param) * randomness);
                    vec4 param_1 = pointPosition;
                    vec4 param_2 = localPosition;
                    uint param_3 = metric;
                    float param_4 = exponent;
                    float distanceToPoint = voronoi_distance_4d(param_1, param_2, param_3, param_4);
                    if (distanceToPoint < minDistance)
                    {
                        targetOffset = cellOffset;
                        minDistance = distanceToPoint;
                        targetPosition = pointPosition;
                    }
                }
            }
        }
    }
    outDistance = minDistance;
    vec4 param_5 = cellPosition + targetOffset;
    outColor = hash_float4_to_float3(param_5);
    outPosition = targetPosition + cellPosition;
}

void voronoi_smooth_f1_4d(vec4 coord, float smoothness, float exponent, float randomness, uint metric, inout float outDistance, inout vec4 outColor, inout vec4 outPosition)
{
    vec4 cellPosition = floor(coord);
    vec4 localPosition = coord - cellPosition;
    float smoothDistance = 8.0;
    vec4 smoothColor = vec4(0.0);
    vec4 smoothPosition = vec4(0.0);
    for (int u = -2; u <= 2; u++)
    {
        for (int k = -2; k <= 2; k++)
        {
            for (int j = -2; j <= 2; j++)
            {
                for (int i = -2; i <= 2; i++)
                {
                    vec4 cellOffset = vec4(float(i), float(j), float(k), float(u));
                    vec4 param = cellPosition + cellOffset;
                    vec4 pointPosition = cellOffset + (hash_float4_to_float4(param) * randomness);
                    vec4 param_1 = pointPosition;
                    vec4 param_2 = localPosition;
                    uint param_3 = metric;
                    float param_4 = exponent;
                    float distanceToPoint = voronoi_distance_4d(param_1, param_2, param_3, param_4);
                    float h = smoothstep(0.0, 1.0, 0.5 + ((0.5 * (smoothDistance - distanceToPoint)) / smoothness));
                    float correctionFactor = (smoothness * h) * (1.0 - h);
                    smoothDistance = mix(smoothDistance, distanceToPoint, h) - correctionFactor;
                    correctionFactor /= (1.0 + (3.0 * smoothness));
                    vec4 param_5 = cellPosition + cellOffset;
                    vec4 cellColor = hash_float4_to_float3(param_5);
                    smoothColor = mix(smoothColor, cellColor, vec4(h)) - vec4(correctionFactor);
                    smoothPosition = mix(smoothPosition, pointPosition, vec4(h)) - vec4(correctionFactor);
                }
            }
        }
    }
    outDistance = smoothDistance;
    outColor = smoothColor;
    outPosition = cellPosition + smoothPosition;
}

void voronoi_f2_4d(vec4 coord, float exponent, float randomness, uint metric, inout float outDistance, inout vec4 outColor, inout vec4 outPosition)
{
    vec4 cellPosition = floor(coord);
    vec4 localPosition = coord - cellPosition;
    float distanceF1 = 8.0;
    float distanceF2 = 8.0;
    vec4 offsetF1 = vec4(0.0);
    vec4 positionF1 = vec4(0.0);
    vec4 offsetF2 = vec4(0.0);
    vec4 positionF2 = vec4(0.0);
    for (int u = -1; u <= 1; u++)
    {
        for (int k = -1; k <= 1; k++)
        {
            for (int j = -1; j <= 1; j++)
            {
                for (int i = -1; i <= 1; i++)
                {
                    vec4 cellOffset = vec4(float(i), float(j), float(k), float(u));
                    vec4 param = cellPosition + cellOffset;
                    vec4 pointPosition = cellOffset + (hash_float4_to_float4(param) * randomness);
                    vec4 param_1 = pointPosition;
                    vec4 param_2 = localPosition;
                    uint param_3 = metric;
                    float param_4 = exponent;
                    float distanceToPoint = voronoi_distance_4d(param_1, param_2, param_3, param_4);
                    if (distanceToPoint < distanceF1)
                    {
                        distanceF2 = distanceF1;
                        distanceF1 = distanceToPoint;
                        offsetF2 = offsetF1;
                        offsetF1 = cellOffset;
                        positionF2 = positionF1;
                        positionF1 = pointPosition;
                    }
                    else
                    {
                        if (distanceToPoint < distanceF2)
                        {
                            distanceF2 = distanceToPoint;
                            offsetF2 = cellOffset;
                            positionF2 = pointPosition;
                        }
                    }
                }
            }
        }
    }
    outDistance = distanceF2;
    vec4 param_5 = cellPosition + offsetF2;
    outColor = hash_float4_to_float3(param_5);
    outPosition = positionF2 + cellPosition;
}

void voronoi_distance_to_edge_4d(vec4 coord, float randomness, inout float outDistance)
{
    vec4 cellPosition = floor(coord);
    vec4 localPosition = coord - cellPosition;
    vec4 vectorToClosest = vec4(0.0);
    float minDistance = 8.0;
    for (int u = -1; u <= 1; u++)
    {
        for (int k = -1; k <= 1; k++)
        {
            for (int j = -1; j <= 1; j++)
            {
                for (int i = -1; i <= 1; i++)
                {
                    vec4 cellOffset = vec4(float(i), float(j), float(k), float(u));
                    vec4 param = cellPosition + cellOffset;
                    vec4 vectorToPoint = (cellOffset + (hash_float4_to_float4(param) * randomness)) - localPosition;
                    float distanceToPoint = dot(vectorToPoint, vectorToPoint);
                    if (distanceToPoint < minDistance)
                    {
                        minDistance = distanceToPoint;
                        vectorToClosest = vectorToPoint;
                    }
                }
            }
        }
    }
    minDistance = 8.0;
    for (int u_1 = -1; u_1 <= 1; u_1++)
    {
        for (int k_1 = -1; k_1 <= 1; k_1++)
        {
            for (int j_1 = -1; j_1 <= 1; j_1++)
            {
                for (int i_1 = -1; i_1 <= 1; i_1++)
                {
                    vec4 cellOffset_1 = vec4(float(i_1), float(j_1), float(k_1), float(u_1));
                    vec4 param_1 = cellPosition + cellOffset_1;
                    vec4 vectorToPoint_1 = (cellOffset_1 + (hash_float4_to_float4(param_1) * randomness)) - localPosition;
                    vec4 perpendicularToEdge = vectorToPoint_1 - vectorToClosest;
                    if (dot(perpendicularToEdge, perpendicularToEdge) > 9.9999997473787516355514526367188e-05)
                    {
                        float distanceToEdge = dot((vectorToClosest + vectorToPoint_1) / vec4(2.0), normalize(perpendicularToEdge));
                        minDistance = min(minDistance, distanceToEdge);
                    }
                }
            }
        }
    }
    outDistance = minDistance;
}

void voronoi_n_sphere_radius_4d(vec4 coord, float randomness, inout float outRadius)
{
    vec4 cellPosition = floor(coord);
    vec4 localPosition = coord - cellPosition;
    vec4 closestPoint = vec4(0.0);
    vec4 closestPointOffset = vec4(0.0);
    float minDistance = 8.0;
    for (int u = -1; u <= 1; u++)
    {
        for (int k = -1; k <= 1; k++)
        {
            for (int j = -1; j <= 1; j++)
            {
                for (int i = -1; i <= 1; i++)
                {
                    vec4 cellOffset = vec4(float(i), float(j), float(k), float(u));
                    vec4 param = cellPosition + cellOffset;
                    vec4 pointPosition = cellOffset + (hash_float4_to_float4(param) * randomness);
                    float distanceToPoint = distance(pointPosition, localPosition);
                    if (distanceToPoint < minDistance)
                    {
                        minDistance = distanceToPoint;
                        closestPoint = pointPosition;
                        closestPointOffset = cellOffset;
                    }
                }
            }
        }
    }
    minDistance = 8.0;
    vec4 closestPointToClosestPoint = vec4(0.0);
    for (int u_1 = -1; u_1 <= 1; u_1++)
    {
        for (int k_1 = -1; k_1 <= 1; k_1++)
        {
            for (int j_1 = -1; j_1 <= 1; j_1++)
            {
                for (int i_1 = -1; i_1 <= 1; i_1++)
                {
                    if ((((i_1 == 0) && (j_1 == 0)) && (k_1 == 0)) && (u_1 == 0))
                    {
                        continue;
                    }
                    vec4 cellOffset_1 = vec4(float(i_1), float(j_1), float(k_1), float(u_1)) + closestPointOffset;
                    vec4 param_1 = cellPosition + cellOffset_1;
                    vec4 pointPosition_1 = cellOffset_1 + (hash_float4_to_float4(param_1) * randomness);
                    float distanceToPoint_1 = distance(closestPoint, pointPosition_1);
                    if (distanceToPoint_1 < minDistance)
                    {
                        minDistance = distanceToPoint_1;
                        closestPointToClosestPoint = pointPosition_1;
                    }
                }
            }
        }
    }
    outRadius = distance(closestPointToClosestPoint, closestPoint) / 2.0;
}

vec4 safe_divide_float4_float(vec4 a, float b)
{
    vec4 _379;
    if (!(b == 0.0))
    {
        _379 = a / vec4(b);
    }
    else
    {
        _379 = vec4(0.0);
    }
    return _379;
}

void svm_node_tex_voronoi()
{
    float distance_out = 0.0;
    float w_out = 0.0;
    float radius_out = 0.0;
    vec4 color_out = vec4(0.0);
    vec4 position_out = vec4(0.0);
    float randomness = clamp(nio.randomness, 0.0, 1.0);
    float smoothness = clamp(nio.smoothness / 2.0, 0.0, 0.5);
    nio.w *= nio.scale;
    nio.coord *= nio.scale;
    switch (nio.dimensions)
    {
        case 1u:
        {
            switch (nio.feature)
            {
                case 0u:
                {
                    float param = nio.w;
                    float param_1 = nio.exponent;
                    float param_2 = randomness;
                    uint param_3 = nio.metric;
                    float param_4 = distance_out;
                    vec4 param_5 = color_out;
                    float param_6 = w_out;
                    voronoi_f1_1d(param, param_1, param_2, param_3, param_4, param_5, param_6);
                    distance_out = param_4;
                    color_out = param_5;
                    w_out = param_6;
                    break;
                }
                case 2u:
                {
                    float param_7 = nio.w;
                    float param_8 = smoothness;
                    float param_9 = nio.exponent;
                    float param_10 = randomness;
                    uint param_11 = nio.metric;
                    float param_12 = distance_out;
                    vec4 param_13 = color_out;
                    float param_14 = w_out;
                    voronoi_smooth_f1_1d(param_7, param_8, param_9, param_10, param_11, param_12, param_13, param_14);
                    distance_out = param_12;
                    color_out = param_13;
                    w_out = param_14;
                    break;
                }
                case 1u:
                {
                    float param_15 = nio.w;
                    float param_16 = nio.exponent;
                    float param_17 = randomness;
                    uint param_18 = nio.metric;
                    float param_19 = distance_out;
                    vec4 param_20 = color_out;
                    float param_21 = w_out;
                    voronoi_f2_1d(param_15, param_16, param_17, param_18, param_19, param_20, param_21);
                    distance_out = param_19;
                    color_out = param_20;
                    w_out = param_21;
                    break;
                }
                case 3u:
                {
                    float param_22 = nio.w;
                    float param_23 = randomness;
                    float param_24 = distance_out;
                    voronoi_distance_to_edge_1d(param_22, param_23, param_24);
                    distance_out = param_24;
                    break;
                }
                case 4u:
                {
                    float param_25 = nio.w;
                    float param_26 = randomness;
                    float param_27 = radius_out;
                    voronoi_n_sphere_radius_1d(param_25, param_26, param_27);
                    radius_out = param_27;
                    break;
                }
                default:
                {
                    if (true)
                    {
                        // unimplemented ext op 12
                    }
                    break;
                }
            }
            float param_28 = w_out;
            float param_29 = nio.scale;
            w_out = safe_divide(param_28, param_29);
            break;
        }
        case 2u:
        {
            vec2 coord_2d = vec2(nio.coord.x, nio.coord.y);
            vec2 position_out_2d;
            switch (nio.feature)
            {
                case 0u:
                {
                    vec2 param_30 = coord_2d;
                    float param_31 = nio.exponent;
                    float param_32 = randomness;
                    uint param_33 = nio.metric;
                    float param_34 = distance_out;
                    vec4 param_35 = color_out;
                    vec2 param_36 = position_out_2d;
                    voronoi_f1_2d(param_30, param_31, param_32, param_33, param_34, param_35, param_36);
                    distance_out = param_34;
                    color_out = param_35;
                    position_out_2d = param_36;
                    break;
                }
                case 2u:
                {
                    vec2 param_37 = coord_2d;
                    float param_38 = smoothness;
                    float param_39 = nio.exponent;
                    float param_40 = randomness;
                    uint param_41 = nio.metric;
                    float param_42 = distance_out;
                    vec4 param_43 = color_out;
                    vec2 param_44 = position_out_2d;
                    voronoi_smooth_f1_2d(param_37, param_38, param_39, param_40, param_41, param_42, param_43, param_44);
                    distance_out = param_42;
                    color_out = param_43;
                    position_out_2d = param_44;
                    break;
                }
                case 1u:
                {
                    vec2 param_45 = coord_2d;
                    float param_46 = nio.exponent;
                    float param_47 = randomness;
                    uint param_48 = nio.metric;
                    float param_49 = distance_out;
                    vec4 param_50 = color_out;
                    vec2 param_51 = position_out_2d;
                    voronoi_f2_2d(param_45, param_46, param_47, param_48, param_49, param_50, param_51);
                    distance_out = param_49;
                    color_out = param_50;
                    position_out_2d = param_51;
                    break;
                }
                case 3u:
                {
                    vec2 param_52 = coord_2d;
                    float param_53 = randomness;
                    float param_54 = distance_out;
                    voronoi_distance_to_edge_2d(param_52, param_53, param_54);
                    distance_out = param_54;
                    break;
                }
                case 4u:
                {
                    vec2 param_55 = coord_2d;
                    float param_56 = randomness;
                    float param_57 = radius_out;
                    voronoi_n_sphere_radius_2d(param_55, param_56, param_57);
                    radius_out = param_57;
                    break;
                }
                default:
                {
                    if (true)
                    {
                        // unimplemented ext op 12
                    }
                    break;
                }
            }
            position_out_2d = safe_divide_float2_float(position_out_2d, nio.scale);
            position_out = vec4(position_out_2d.x, position_out_2d.y, 0.0, 0.0);
            break;
        }
        case 3u:
        {
            switch (nio.feature)
            {
                case 0u:
                {
                    vec4 param_58 = vec4(nio.coord, 0.0);
                    float param_59 = nio.exponent;
                    float param_60 = randomness;
                    uint param_61 = nio.metric;
                    float param_62 = distance_out;
                    vec4 param_63 = color_out;
                    vec4 param_64 = position_out;
                    voronoi_f1_3d(param_58, param_59, param_60, param_61, param_62, param_63, param_64);
                    distance_out = param_62;
                    color_out = param_63;
                    position_out = param_64;
                    break;
                }
                case 2u:
                {
                    vec4 param_65 = vec4(nio.coord, 0.0);
                    float param_66 = smoothness;
                    float param_67 = nio.exponent;
                    float param_68 = randomness;
                    uint param_69 = nio.metric;
                    float param_70 = distance_out;
                    vec4 param_71 = color_out;
                    vec4 param_72 = position_out;
                    voronoi_smooth_f1_3d(param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);
                    distance_out = param_70;
                    color_out = param_71;
                    position_out = param_72;
                    break;
                }
                case 1u:
                {
                    vec4 param_73 = vec4(nio.coord, 0.0);
                    float param_74 = nio.exponent;
                    float param_75 = randomness;
                    uint param_76 = nio.metric;
                    float param_77 = distance_out;
                    vec4 param_78 = color_out;
                    vec4 param_79 = position_out;
                    voronoi_f2_3d(param_73, param_74, param_75, param_76, param_77, param_78, param_79);
                    distance_out = param_77;
                    color_out = param_78;
                    position_out = param_79;
                    break;
                }
                case 3u:
                {
                    vec4 param_80 = vec4(nio.coord, 0.0);
                    float param_81 = randomness;
                    float param_82 = distance_out;
                    voronoi_distance_to_edge_3d(param_80, param_81, param_82);
                    distance_out = param_82;
                    break;
                }
                case 4u:
                {
                    vec4 param_83 = vec4(nio.coord, 0.0);
                    float param_84 = randomness;
                    float param_85 = radius_out;
                    voronoi_n_sphere_radius_3d(param_83, param_84, param_85);
                    radius_out = param_85;
                    break;
                }
                default:
                {
                    if (true)
                    {
                        // unimplemented ext op 12
                    }
                    break;
                }
            }
            position_out = safe_divide_float3_float(position_out, nio.scale);
            break;
        }
        case 4u:
        {
            vec4 coord_4d = vec4(nio.coord.x, nio.coord.y, nio.coord.z, nio.w);
            vec4 position_out_4d;
            switch (nio.feature)
            {
                case 0u:
                {
                    vec4 param_86 = coord_4d;
                    float param_87 = nio.exponent;
                    float param_88 = randomness;
                    uint param_89 = nio.metric;
                    float param_90 = distance_out;
                    vec4 param_91 = color_out;
                    vec4 param_92 = position_out_4d;
                    voronoi_f1_4d(param_86, param_87, param_88, param_89, param_90, param_91, param_92);
                    distance_out = param_90;
                    color_out = param_91;
                    position_out_4d = param_92;
                    break;
                }
                case 2u:
                {
                    vec4 param_93 = coord_4d;
                    float param_94 = smoothness;
                    float param_95 = nio.exponent;
                    float param_96 = randomness;
                    uint param_97 = nio.metric;
                    float param_98 = distance_out;
                    vec4 param_99 = color_out;
                    vec4 param_100 = position_out_4d;
                    voronoi_smooth_f1_4d(param_93, param_94, param_95, param_96, param_97, param_98, param_99, param_100);
                    distance_out = param_98;
                    color_out = param_99;
                    position_out_4d = param_100;
                    break;
                }
                case 1u:
                {
                    vec4 param_101 = coord_4d;
                    float param_102 = nio.exponent;
                    float param_103 = randomness;
                    uint param_104 = nio.metric;
                    float param_105 = distance_out;
                    vec4 param_106 = color_out;
                    vec4 param_107 = position_out_4d;
                    voronoi_f2_4d(param_101, param_102, param_103, param_104, param_105, param_106, param_107);
                    distance_out = param_105;
                    color_out = param_106;
                    position_out_4d = param_107;
                    break;
                }
                case 3u:
                {
                    vec4 param_108 = coord_4d;
                    float param_109 = randomness;
                    float param_110 = distance_out;
                    voronoi_distance_to_edge_4d(param_108, param_109, param_110);
                    distance_out = param_110;
                    break;
                }
                case 4u:
                {
                    vec4 param_111 = coord_4d;
                    float param_112 = randomness;
                    float param_113 = radius_out;
                    voronoi_n_sphere_radius_4d(param_111, param_112, param_113);
                    radius_out = param_113;
                    break;
                }
                default:
                {
                    if (true)
                    {
                        // unimplemented ext op 12
                    }
                    break;
                }
            }
            position_out_4d = safe_divide_float4_float(position_out_4d, nio.scale);
            position_out = vec4(position_out_4d.x, position_out_4d.y, position_out_4d.z, 0.0);
            w_out = position_out_4d.w;
            break;
        }
        default:
        {
            break;
        }
    }
    nio.coord = color_out.xyz;
    nio.w = w_out;
    nio.scale = radius_out;
    nio.smoothness = distance_out;
    nio.exponent = position_out.x;
    nio.randomness = position_out.y;
    nio.feature = floatBitsToUint(position_out.z);
}

void main()
{
    null_flt = 3.4028234663852885981170418348452e+38;
    null_flt2 = vec2(3.4028234663852885981170418348452e+38);
    null_flt3 = vec4(3.4028234663852885981170418348452e+38);
    null_flt4 = vec4(3.4028234663852885981170418348452e+38);
    null_int = -2147483648;
    INTERPOLATION_NONE = 4294967295u;
    INTERPOLATION_LINEAR = 0u;
    INTERPOLATION_CLOSEST = 1u;
    INTERPOLATION_CUBIC = 2u;
    INTERPOLATION_SMART = 3u;
    INTERPOLATION_NUM_TYPES = 4u;
    IMAGE_DATA_TYPE_FLOAT4 = 0u;
    IMAGE_DATA_TYPE_BYTE4 = 1u;
    IMAGE_DATA_TYPE_HALF4 = 2u;
    IMAGE_DATA_TYPE_FLOAT = 3u;
    IMAGE_DATA_TYPE_BYTE = 4u;
    IMAGE_DATA_TYPE_HALF = 5u;
    IMAGE_DATA_TYPE_USHORT4 = 6u;
    IMAGE_DATA_TYPE_USHORT = 7u;
    IMAGE_DATA_NUM_TYPES = 8u;
    IMAGE_ALPHA_UNASSOCIATED = 0u;
    IMAGE_ALPHA_ASSOCIATED = 1u;
    IMAGE_ALPHA_CHANNEL_PACKED = 2u;
    IMAGE_ALPHA_IGNORE = 3u;
    IMAGE_ALPHA_AUTO = 4u;
    IMAGE_ALPHA_NUM_TYPES = 5u;
    EXTENSION_REPEAT = 0u;
    EXTENSION_EXTEND = 1u;
    EXTENSION_CLIP = 2u;
    EXTENSION_NUM_TYPES = 3u;
    svm_node_tex_voronoi();
}


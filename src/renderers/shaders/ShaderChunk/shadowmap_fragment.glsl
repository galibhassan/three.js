vec3 shadowMask = vec3( 1.0 );

#ifdef USE_SHADOWMAP

	float shadows[ NUM_SHADOWS ];

	for ( int i = 0; i < NUM_SHADOWS; i ++ ) {

		vec2 texelSize = vec2( 1.0 ) / shadowMapSize[ i ];

		float shadow = 0.0;

#ifdef POINT_LIGHT_SHADOWS

		// to save on uniform space, we use the sign of @shadowDarkness[ i ] to determine
		// whether or not this light is a point light ( shadowDarkness[ i ] < 0 == point light)
		bool isPointLight = shadowDarkness[ i ] < 0.0;

		if ( isPointLight ) {

			// get the real shadow darkness
			float realShadowDarkness = abs( shadowDarkness[ i ] );

			// for point lights, the uniform @vShadowCoord is re-purposed to hold
			// the distance from the light to the world-space position of the fragment.
			vec3 lightToPosition = vShadowCoord[ i ].xyz;

			// bd3D = base direction 3D
			vec3 bd3D = normalize( lightToPosition );
			// dp = distance from light to fragment position
			float dp = ( length( lightToPosition ) - shadowBias[ i ] ) / 1000.0;

	#if defined( SHADOWMAP_TYPE_PCF ) || defined( SHADOWMAP_TYPE_PCF_SOFT )

			// Dr = disk radius

	#if defined( SHADOWMAP_TYPE_PCF )
			const float Dr = 1.25;
	#elif defined( SHADOWMAP_TYPE_PCF_SOFT )
			const float Dr = 2.25;
	#endif

			// os = offset scale
			float os = Dr * 2.0 * texelSize.y;

			const vec3 Gsd = vec3( - 1, 0, 1 );

			shadow += texture2DCompare( shadowMap[ i ], cubeToUV( bd3D + Gsd.zzz * os, texelSize.y ), dp );
			shadow += texture2DCompare( shadowMap[ i ], cubeToUV( bd3D + Gsd.zxz * os, texelSize.y ), dp );
			shadow += texture2DCompare( shadowMap[ i ], cubeToUV( bd3D + Gsd.xxz * os, texelSize.y ), dp );
			shadow += texture2DCompare( shadowMap[ i ], cubeToUV( bd3D + Gsd.xzz * os, texelSize.y ), dp );
			shadow += texture2DCompare( shadowMap[ i ], cubeToUV( bd3D + Gsd.zzx * os, texelSize.y ), dp );
			shadow += texture2DCompare( shadowMap[ i ], cubeToUV( bd3D + Gsd.zxx * os, texelSize.y ), dp );
			shadow += texture2DCompare( shadowMap[ i ], cubeToUV( bd3D + Gsd.xxx * os, texelSize.y ), dp );
			shadow += texture2DCompare( shadowMap[ i ], cubeToUV( bd3D + Gsd.xzx * os, texelSize.y ), dp );
			shadow += texture2DCompare( shadowMap[ i ], cubeToUV( bd3D + Gsd.zzy * os, texelSize.y ), dp );
			shadow += texture2DCompare( shadowMap[ i ], cubeToUV( bd3D + Gsd.zxy * os, texelSize.y ), dp );
			shadow += texture2DCompare( shadowMap[ i ], cubeToUV( bd3D, texelSize.y ), dp );
			shadow += texture2DCompare( shadowMap[ i ], cubeToUV( bd3D + Gsd.xxy * os, texelSize.y ), dp );
			shadow += texture2DCompare( shadowMap[ i ], cubeToUV( bd3D + Gsd.xzy * os, texelSize.y ), dp );
			shadow += texture2DCompare( shadowMap[ i ], cubeToUV( bd3D + Gsd.zyz * os, texelSize.y ), dp );
			shadow += texture2DCompare( shadowMap[ i ], cubeToUV( bd3D + Gsd.xyz * os, texelSize.y ), dp );
			shadow += texture2DCompare( shadowMap[ i ], cubeToUV( bd3D + Gsd.zyx * os, texelSize.y ), dp );
			shadow += texture2DCompare( shadowMap[ i ], cubeToUV( bd3D + Gsd.xyx * os, texelSize.y ), dp );
			shadow += texture2DCompare( shadowMap[ i ], cubeToUV( bd3D + Gsd.yzz * os, texelSize.y ), dp );
			shadow += texture2DCompare( shadowMap[ i ], cubeToUV( bd3D + Gsd.yxz * os, texelSize.y ), dp );
			shadow += texture2DCompare( shadowMap[ i ], cubeToUV( bd3D + Gsd.yxx * os, texelSize.y ), dp );
			shadow += texture2DCompare( shadowMap[ i ], cubeToUV( bd3D + Gsd.yzx * os, texelSize.y ), dp );

			shadow *= realShadowDarkness * ( 1.0 / 21.0 );

	#else // no percentage-closer filtering

			shadow = texture2DCompare( shadowMap[ i ], cubeToUV( bd3D, texelSize.y ), dp ) * realShadowDarkness;

	#endif

		} else {

#endif // POINT_LIGHT_SHADOWS

			vec3 shadowCoord = vShadowCoord[ i ].xyz / vShadowCoord[ i ].w;

			// if ( something && something ) breaks ATI OpenGL shader compiler
			// if ( all( something, something ) ) using this instead

			bvec4 inFrustumVec = bvec4 ( shadowCoord.x >= 0.0, shadowCoord.x <= 1.0, shadowCoord.y >= 0.0, shadowCoord.y <= 1.0 );
			bool inFrustum = all( inFrustumVec );

			bvec2 frustumTestVec = bvec2( inFrustum, shadowCoord.z <= 1.0 );

			bool frustumTest = all( frustumTestVec );

			if ( frustumTest ) {

				shadowCoord.z += shadowBias[ i ];

	#if defined( SHADOWMAP_TYPE_PCF )

				float dx0 = - texelSize.x;
				float dy0 = - texelSize.y;
				float dx1 = + texelSize.x;
				float dy1 = + texelSize.y;

				shadow += texture2DCompare( shadowMap[ i ], shadowCoord.xy + vec2( dx0, dy0 ), shadowCoord.z );
				shadow += texture2DCompare( shadowMap[ i ], shadowCoord.xy + vec2( 0.0, dy0 ), shadowCoord.z );
				shadow += texture2DCompare( shadowMap[ i ], shadowCoord.xy + vec2( dx1, dy0 ), shadowCoord.z );
				shadow += texture2DCompare( shadowMap[ i ], shadowCoord.xy + vec2( dx0, 0.0 ), shadowCoord.z );
				shadow += texture2DCompare( shadowMap[ i ], shadowCoord.xy, shadowCoord.z );
				shadow += texture2DCompare( shadowMap[ i ], shadowCoord.xy + vec2( dx1, 0.0 ), shadowCoord.z );
				shadow += texture2DCompare( shadowMap[ i ], shadowCoord.xy + vec2( dx0, dy1 ), shadowCoord.z );
				shadow += texture2DCompare( shadowMap[ i ], shadowCoord.xy + vec2( 0.0, dy1 ), shadowCoord.z );
				shadow += texture2DCompare( shadowMap[ i ], shadowCoord.xy + vec2( dx1, dy1 ), shadowCoord.z );
				shadow *= 1.0 / 9.0;

				shadow *= shadowDarkness[ i ];

	#elif defined( SHADOWMAP_TYPE_PCF_SOFT )

				float dx0 = - texelSize.x;
				float dy0 = - texelSize.y;
				float dx1 = + texelSize.x;
				float dy1 = + texelSize.y;

				mat3 shadowKernel;
				mat3 depthKernel;

				depthKernel[ 0 ][ 0 ] = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( dx0, dy0 ) ) );
				depthKernel[ 0 ][ 1 ] = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( dx0, 0.0 ) ) );
				depthKernel[ 0 ][ 2 ] = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( dx0, dy1 ) ) );
				depthKernel[ 1 ][ 0 ] = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( 0.0, dy0 ) ) );
				depthKernel[ 1 ][ 1 ] = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy ) );
				depthKernel[ 1 ][ 2 ] = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( 0.0, dy1 ) ) );
				depthKernel[ 2 ][ 0 ] = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( dx1, dy0 ) ) );
				depthKernel[ 2 ][ 1 ] = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( dx1, 0.0 ) ) );
				depthKernel[ 2 ][ 2 ] = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( dx1, dy1 ) ) );

				vec3 shadowZ = vec3( shadowCoord.z );
				shadowKernel[ 0 ] = vec3( lessThan( depthKernel[ 0 ], shadowZ ) );
				shadowKernel[ 0 ] *= vec3( 0.25 );

				shadowKernel[ 1 ] = vec3( lessThan( depthKernel[ 1 ], shadowZ ) );
				shadowKernel[ 1 ] *= vec3( 0.25 );

				shadowKernel[ 2 ] = vec3( lessThan( depthKernel[ 2 ], shadowZ ) );
				shadowKernel[ 2 ] *= vec3( 0.25 );

				vec2 fractionalCoord = 1.0 - fract( shadowCoord.xy * shadowMapSize[ i ].xy );

				shadowKernel[ 0 ] = mix( shadowKernel[ 1 ], shadowKernel[ 0 ], fractionalCoord.x );
				shadowKernel[ 1 ] = mix( shadowKernel[ 2 ], shadowKernel[ 1 ], fractionalCoord.x );

				vec4 shadowValues;
				shadowValues.x = mix( shadowKernel[ 0 ][ 1 ], shadowKernel[ 0 ][ 0 ], fractionalCoord.y );
				shadowValues.y = mix( shadowKernel[ 0 ][ 2 ], shadowKernel[ 0 ][ 1 ], fractionalCoord.y );
				shadowValues.z = mix( shadowKernel[ 1 ][ 1 ], shadowKernel[ 1 ][ 0 ], fractionalCoord.y );
				shadowValues.w = mix( shadowKernel[ 1 ][ 2 ], shadowKernel[ 1 ][ 1 ], fractionalCoord.y );

				shadow = dot( shadowValues, vec4( 1.0 ) ) * shadowDarkness[ i ];

	#else // no percentage-closer filtering:

				shadow = texture2DCompare( shadowMap[ i ], shadowCoord.xy, shadowCoord.z ) * shadowDarkness[ i ];

	#endif

			}

#ifdef SHADOWMAP_DEBUG

			if ( inFrustum ) {

				if ( i == 0 ) {

					outgoingLight *= vec3( 1.0, 0.5, 0.0 );

				} else if ( i == 1 ) {

					outgoingLight *= vec3( 0.0, 1.0, 0.8 );

				} else {

					outgoingLight *= vec3( 0.0, 0.5, 1.0 );

				}

			}

#endif

#ifdef POINT_LIGHT_SHADOWS

		}

#endif

		shadowMask = shadowMask * vec3( 1.0 - shadow );

		shadows[ i ] = 1.0 - shadow;

	}

#endif

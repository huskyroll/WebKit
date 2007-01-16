/*
 Copyright (C) 2007 Eric Seidel <eric@webkit.org>
 
 This file is part of the WebKit project
 
 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Library General Public
 License as published by the Free Software Foundation; either
 version 2 of the License, or (at your option) any later version.
 
 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Library General Public License for more details.
 
 You should have received a copy of the GNU Library General Public License
 along with this library; see the file COPYING.LIB.  If not, write to
 the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 Boston, MA 02111-1307, USA.
 */

#ifndef SVGAnimateMotionElement_h
#define SVGAnimateMotionElement_h
#ifdef SVG_SUPPORT

#include "SVGAnimationElement.h"
#include "AffineTransform.h"
#include "Path.h"

namespace WebCore {
            
    class SVGAnimateMotionElement : public SVGAnimationElement {
    public:
        SVGAnimateMotionElement(const QualifiedName&, Document*);
        virtual ~SVGAnimateMotionElement();
        
        virtual bool hasValidTarget() const;
        
        virtual void parseMappedAttribute(MappedAttribute*);
        
        void applyAnimationToValue(SVGTransformList*);
        
        Path animationPath();
        
    protected:
        virtual const SVGElement* contextElement() const { return this; }
        
        virtual bool updateCurrentValue(double timePercentage);
        virtual bool handleStartCondition();
        
    private:
        Path m_path;
        Vector<float> m_keyPoints;
        enum RotateMode {
            AngleMode,
            AutoMode,
            AutoReverseMode
        };
        RotateMode m_rotateMode;
        float m_angle;
        AffineTransform m_currentTransform;
    };
    
} // namespace WebCore

#endif // SVG_SUPPORT
#endif // SVGAnimateMotionElement_h

// vim:ts=4:noet

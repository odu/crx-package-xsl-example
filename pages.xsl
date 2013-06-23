<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
               xmlns:xs="http://www.w3.org/2001/XMLSchema"
               xmlns:java="http://www.java.com/"
               xmlns:rep="internal"
               xmlns:jcr="http://www.jcp.org/jcr/1.0"
               xmlns:crx="http://www.day.com/crx/1.0"
               xmlns:exslt="http://exslt.org/common"
               exclude-result-prefixes="exslt java xs"
               version="2.0">

    <!-- crx-package-xsl vault helper -->
    <xsl:import href="lib/vault.xsl"/>

    <!-- helper used to detect if a file alread exists -->
    <xsl:import href="lib/file-exists.xsl"/>

    <xsl:output method="xml" indent="yes" name="xml"/>

    <!-- Vault Parameters -->
    <xsl:variable name="package-name">Sample Pages Package</xsl:variable>
    <xsl:variable name="package-description">Sample Pages Package</xsl:variable>
    <xsl:variable name="package-filter">/content/example</xsl:variable>
    <xsl:variable name="package-root">package/jcr_root</xsl:variable>
    <xsl:variable name="meta-root">package/META-INF</xsl:variable>

    <!-- Pages Variables -->
    <xsl:variable name="page-resource-type">geometrixx/components/contentpage</xsl:variable>
    <xsl:variable name="page-template">/apps/geometrixx/templates/contentpage</xsl:variable>
    <xsl:variable name="page-design">/etc/designs/geometrixx</xsl:variable>
    <xsl:variable name="page-design-root">/content/example</xsl:variable>


    <xsl:template match="/">
        <xsl:for-each select="//page">
            <xsl:call-template name="build-pages">
                <xsl:with-param name="path" select="path" />
                <xsl:with-param name="title" select="title" />
                <xsl:with-param name="description" select="description" />
            </xsl:call-template>
        </xsl:for-each>

        <!-- Include Standard Vault Files -->
        <xsl:call-template name="vault-files" />

    </xsl:template>

    <!-- This is a recurssive template that builds the pages and parent pages -->
    <xsl:template name="build-pages">
        <xsl:param name="path" />
        <xsl:param name="name" />
        <xsl:param name="title" />
        <xsl:param name="description" />
        <xsl:param name="is-recursive" />

        <xsl:choose>
            <xsl:when test="$path = '' or $path = '/'">
                <!-- reached root -->
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="java:file-exists(concat($package-root, $path, '/.content.xml'), base-uri())">
                        <!-- content file already exists -->
                    </xsl:when>
                    <xsl:when test="$is-recursive = 'true' and //page/path = $path">
                        <!-- Catch a deeper call trying to create a page defined later in the file -->
                    </xsl:when>
                    <xsl:otherwise>                    
                        <xsl:result-document href="{concat($package-root, $path, '/.content.xml')}" indent="yes" method="xml">
                            <jcr:root xmlns:sling="http://sling.apache.org/jcr/sling/1.0"
                                      xmlns:cq="http://www.day.com/jcr/cq/1.0"
                                      xmlns:jcr="http://www.jcp.org/jcr/1.0"
                                      jcr:primaryType="cq:Page">
                                
                                <xsl:element name="jcr:content">
                                    <xsl:attribute name="jcr:primaryType">cq:PageContent</xsl:attribute>
                                    <xsl:attribute name="cq:template">
                                        <xsl:value-of select="$page-template"/>
                                    </xsl:attribute>
                                    <xsl:attribute name="sling:resourceType">
                                        <xsl:value-of select="$page-resource-type"/>
                                    </xsl:attribute>
                                    <xsl:attribute name="jcr:title">
                                        <xsl:value-of select="$title"/>
                                    </xsl:attribute>
                                    <xsl:if test="$description">
                                        <xsl:attribute name="jcr:description">
                                            <xsl:value-of select="$description"/>
                                        </xsl:attribute>
                                    </xsl:if>
                                    <xsl:if test="$path = $page-design-root">
                                        <xsl:attribute name="cq:designPath">
                                            <xsl:value-of select="$page-design"/>
                                        </xsl:attribute>
                                    </xsl:if>
                                </xsl:element>

                                <!-- Include other pages at the same level -->
                                <xsl:variable name="same-level-pages">
                                    <!-- This loop builds a temporary node structure of the node names at the current level -->
                                    <xsl:element name="pages">
                                        <xsl:for-each select="//page[matches(path, concat($path, '/[^/]+'))]">
                                            <xsl:element name="page">
                                                <xsl:value-of select="replace(path, concat($path, '/([^/]+)/?.*'), '$1')"></xsl:value-of>
                                            </xsl:element>
                                        </xsl:for-each>
                                    </xsl:element>
                                </xsl:variable>

                                <xsl:variable name="same-level" select="exslt:node-set($same-level-pages)/*" />
                                <xsl:for-each select="$same-level//page">
                                    <xsl:variable name="dot">
                                        <xsl:value-of select="."></xsl:value-of>
                                    </xsl:variable>
                                    <!-- prevent duplicates by making sure the isn't one before it -->
                                    <xsl:if test="not(preceding-sibling::page[. = $dot])">
                                        <!-- if a node starts with a number it gets converted to _x003#_ -->
                                        <xsl:element name="{replace($dot, '^(\d)', '_x003$1_')}"></xsl:element>
                                    </xsl:if>
                                </xsl:for-each>
                            </jcr:root>
                        </xsl:result-document>
                    </xsl:otherwise>
                </xsl:choose>

                <!-- rcuresive call to create any necessary parents -->
                <xsl:call-template name="build-pages">
                    <xsl:with-param name="path" select="replace($path, '/[^/]*$', '')" />
                    <xsl:with-param name="name" select="replace($path, '.*/([^/]*$)', '$1')" />
                    <xsl:with-param name="title" select="replace($path, '.*/([^/]*$)', '$1')" />
                    <xsl:with-param name="is-recursive" select="'true'" />
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:transform>
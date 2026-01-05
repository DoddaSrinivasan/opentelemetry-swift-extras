import OpenTelemetryApi
import OpenTelemetryConcurrency

public extension Span {
    var current: Span? {
        OpenTelemetryConcurrency.OpenTelemetry.instance.contextProvider.activeSpan
    }
}

public extension SpanBuilderBase {
    @discardableResult func setParent(
        _ parent: Span?
    ) -> Self {
        if let parent = parent {
            setParent(parent)
        } else {
            setNoParent()
        }
    }
    
    @discardableResult func setAttributes(
        _ attributes: [String: String] = [:]
    ) -> Self {
        attributes.forEach { key, value in
            setAttribute(key: key, value: value)
        }
        return self
    }
}

// Async
public func childSpan<T>(
    _ name: String,
    instrumentationName: String,
    parent: Span? = OpenTelemetryConcurrency.OpenTelemetry.instance.contextProvider.activeSpan,
    attributes: [String: String] = [:],
    operation: (Span?) async -> T
) async -> T {
    await makeSpanBuilder(
        name,
        instrumentationName: instrumentationName,
        parent: parent,
        attributes: attributes
    ).withActiveSpan { span in
        defer { span.status = .ok }
        return await operation(span as? Span)
    }
}

public func throwingChildSpan<T>(
    _ name: String,
    instrumentationName: String,
    parent: Span? = OpenTelemetryConcurrency.OpenTelemetry.instance.contextProvider.activeSpan,
    attributes: [String: String] = [:],
    operation: (Span?) async throws -> T
) async rethrows -> T {
    return try await makeSpanBuilder(
        name,
        instrumentationName: instrumentationName,
        parent: parent,
        attributes: attributes
    ).withActiveSpan { span in
        do {
            let result = try await operation(span as? Span)
            span.status = .ok
            return result
        } catch {
            span.status = .error(description: error.localizedDescription)
            (span as? Span)?.recordException(error)
            throw error
        }
    }
}

// Sync Non throwing
public func childSpan<T>(
    _ name: String,
    instrumentationName: String,
    parent: Span? = OpenTelemetryConcurrency.OpenTelemetry.instance.contextProvider.activeSpan,
    attributes: [String: String] = [:],
    operation: (Span?) -> T
) -> T {
    return makeSpanBuilder(
        name,
        instrumentationName: instrumentationName,
        parent: parent,
        attributes: attributes
    ).withActiveSpan { span in
        defer { span.status = .ok }
        return operation(span as? Span)
    }
}

public func childSpan<T>(
    _ name: String,
    instrumentationName: String,
    parent: Span? = OpenTelemetryConcurrency.OpenTelemetry.instance.contextProvider.activeSpan,
    attributes: [String: String] = [:],
    operation: (Span?) -> T?
) -> T? {
    return makeSpanBuilder(
        name,
        instrumentationName: instrumentationName,
        parent: parent,
        attributes: attributes
    ).withActiveSpan { span in
        defer { span.status = .ok }
        return operation(span as? Span)
    }
}

// Sync throwing
public func throwingChildSpan<T>(
    _ name: String,
    instrumentationName: String,
    parent: Span? = OpenTelemetryConcurrency.OpenTelemetry.instance.contextProvider.activeSpan,
    attributes: [String: String] = [:],
    operation: (Span?) throws -> T
) rethrows -> T {
    return try makeSpanBuilder(
        name,
        instrumentationName: instrumentationName,
        parent: parent,
        attributes: attributes
    ).withActiveSpan { span in
        do {
            let result = try operation(span as? Span)
            span.status = .ok
            return result
        } catch {
            span.status = .error(description: error.localizedDescription)
            (span as? Span)?.recordException(error)
            throw error
        }
    }
}

public func throwingChildSpan<T>(
    _ name: String,
    instrumentationName: String,
    parent: Span? = OpenTelemetryConcurrency.OpenTelemetry.instance.contextProvider.activeSpan,
    attributes: [String: String] = [:],
    operation: (Span?) throws -> T?
) rethrows -> T? {
    return try makeSpanBuilder(
        name,
        instrumentationName: instrumentationName,
        parent: parent,
        attributes: attributes
    ).withActiveSpan { span in
        do {
            let result = try operation(span as? Span)
            span.status = .ok
            return result
        } catch {
            span.status = .error(description: error.localizedDescription)
            (span as? Span)?.recordException(error)
            throw error
        }
    }
}

private func makeSpanBuilder(
    _ name: String,
    instrumentationName: String,
    parent: Span? = OpenTelemetryConcurrency.OpenTelemetry.instance.contextProvider.activeSpan,
    attributes: [String: String] = [:],
) -> SpanBuilderBase {
    OpenTelemetry.instance
        .tracerProvider
        .get(instrumentationName: instrumentationName)
        .spanBuilder(spanName: name)
        .setParent(parent)
        .setAttributes(attributes)
}

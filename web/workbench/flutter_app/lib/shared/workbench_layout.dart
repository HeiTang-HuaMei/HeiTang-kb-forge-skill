part of '../main.dart';

class _ProductColumn extends StatelessWidget {
  const _ProductColumn({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final column = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
      if (!constraints.maxHeight.isFinite) {
        return column;
      }
      return Scrollbar(
        child: SingleChildScrollView(
          primary: false,
          child: column,
        ),
      );
    });
  }
}

class _Grid12Cell {
  const _Grid12Cell({
    required this.span,
    required this.child,
  });

  final int span;
  final Widget child;
}

class _Grid12Row extends StatelessWidget {
  const _Grid12Row({
    required this.cells,
  });

  final List<_Grid12Cell> cells;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < _DesktopGrid.rowBreakpoint) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < cells.length; index++) ...[
              if (index > 0) const SizedBox(height: _DesktopGrid.gutter),
              cells[index].child,
            ],
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < cells.length; index++) ...[
            if (index > 0) const SizedBox(width: _DesktopGrid.gutter),
            Expanded(flex: cells[index].span, child: cells[index].child),
          ],
        ],
      );
    });
  }
}

class _EqualHeightRow extends StatelessWidget {
  const _EqualHeightRow({
    required this.height,
    required this.children,
    this.flexes,
  });

  final double height;
  final List<Widget> children;
  final List<int>? flexes;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < _DesktopGrid.rowBreakpoint) {
        return Column(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              if (index > 0) const SizedBox(height: _DesktopGrid.gutter),
              SizedBox(height: height, child: children[index]),
            ],
          ],
        );
      }
      return SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              if (index > 0) const SizedBox(width: _DesktopGrid.gutter),
              Expanded(
                flex: flexes == null ? 1 : flexes![index],
                child: children[index],
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _EqualActionRow extends StatelessWidget {
  const _EqualActionRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) const SizedBox(height: _DesktopGrid.gutter),
          children[index],
        ],
      ],
    );
  }
}

class _EqualFieldGrid extends StatelessWidget {
  const _EqualFieldGrid({required this.children, this.columns = 2});

  final List<Widget> children;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: children.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: _DesktopGrid.gutter,
        mainAxisSpacing: _DesktopGrid.gutter,
        mainAxisExtent: 94,
      ),
      itemBuilder: (context, index) => children[index],
    );
  }
}

class _FillPanelColumn extends StatelessWidget {
  const _FillPanelColumn({
    required this.top,
    required this.bottom,
  });

  final Widget top;
  final Widget bottom;

  @override
  Widget build(BuildContext context) {
    final filled = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: top),
        const SizedBox(height: _DesktopGrid.gutter),
        bottom,
      ],
    );
    return LayoutBuilder(builder: (context, constraints) {
      if (!constraints.maxHeight.isFinite) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [top, const SizedBox(height: _DesktopGrid.gutter), bottom],
        );
      }
      return SizedBox(
        height: constraints.maxHeight,
        child: filled,
      );
    });
  }
}

class _LocalScrollBox extends StatelessWidget {
  const _LocalScrollBox({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final box = Scrollbar(
      thumbVisibility: false,
      child: SingleChildScrollView(
        primary: false,
        child: _ScrollSafePadding(child: child),
      ),
    );
    return box;
  }
}

class _ScrollSafePadding extends StatelessWidget {
  const _ScrollSafePadding({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: _DesktopGrid.footerSafeArea),
      child: child,
    );
  }
}

class _BoundedScrollRegion extends StatelessWidget {
  const _BoundedScrollRegion({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(_DesktopGrid.panelRadius),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: child,
    );
  }
}

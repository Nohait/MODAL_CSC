import sys, os

PROJECT_ROOT = os.path.dirname(os.path.dirname(__file__))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)


def main():
    try:
        from blender_pipeline.procedural.generators import registry

        gens = registry.list_generators()
        print("Detected generators:")
        for g in gens:
            print(f"- {g}")
        print("IMPORT SUCCESS")
    except Exception as exc:
        print("IMPORT FAILED")
        print(exc)
        raise


if __name__ == "__main__":
    main()
